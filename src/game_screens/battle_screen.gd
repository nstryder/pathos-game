extends Node2D
class_name BattleScreen

signal attack_declared

enum Timeline {
	PLAYER1_OFFENSE,
	PLAYER2_DEFENSE,
	# +1 turn
	PLAYER2_OFFENSE,
	PLAYER1_DEFENSE
	# +1 turn
}

@export var template_entity_deck: Array[String] = []
@export var template_effect_deck: Array[String] = []


# SERVER VARS
var turn_count: int = 1
@export var current_phase: Timeline:
	set(value):
		current_phase = value
		var phase_text: String = str(Timeline.keys()[value]).capitalize()
		(%PhaseLabel as Label).text = "Current phase: " + phase_text

@export var attacking_player: Player
@export var declared_attacker_slot: int
@export var declared_target_slot: int

@onready var player1: Player = $Players/Player1
@onready var player2: Player = $Players/Player2


# CLIENT VARS
var controlled_player: Player
var opposing_player: Player

var queued_effect_attachments: Array[Array] = [[], [], []]
var slot_attachment_history_stack: Array[int] = []

@onready var your_entity_deck: Deck = %YourEntityDeck
@onready var your_effect_deck: Deck = %YourEffectDeck
@onready var your_entity_markers: EntitySlotMarkers = %YourEntitySlotMarkers
@onready var your_hand: PlayerHand = %YourHand
@onready var opp_entity_deck: Deck = %OppEntityDeck
@onready var opp_effect_deck: Deck = %OppEffectDeck
@onready var opp_entity_markers: EntitySlotMarkers = %OppEntitySlotMarkers
@onready var opp_hand: PlayerHand = %OppHand

@onready var button_undo: Button = %UndoButton
@onready var button_skip: Button = %SkipButton


# assign player ids
# shuffle cards
# place entities on field
# both players draw 2 fx cards


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button_undo.hide()
	button_undo.pressed.connect(undo_attachment)
	button_skip.hide()
	button_skip.pressed.connect(skip_phase)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


#region SERVER METHODS

func initialize_board() -> void:
	if not multiplayer.is_server():
		return
	_assign_player_ids()
	_setup_player_decks()
	_draw_initial_entities()
	_finish_client_side_setup.rpc()
	await get_tree().create_timer(1.0).timeout
	# At this point, assume game state is synced and ready to start
	start_game()


func start_game() -> void:
	if not multiplayer.is_server():
		return
	current_phase = Timeline.PLAYER1_OFFENSE
	check_phase()

# TODO
func check_phase() -> void:
	if current_phase == Timeline.PLAYER1_OFFENSE:
		player1.draw_effects()
		attacking_player = player1
		start_client_offense.rpc_id(player1.id)
		await attack_declared
		
		
		# FX cards get drawn if not 1st turn
		# Enable FX cards to be dragged
		# Enable Entities to declare attack
		# await attack declaration
		# - Player sends: FX placed & attack declared (or skip declared)
		# - Advance the timeline
	# For defensive phase:
		# Enable FX cards to be dragged
		# await confirm
		# Player sends: FX placed (or skip declared)
	# Resolve combat
	# Advance turn counter
	# Advance timeline
	# Back to offense


# TODO
@rpc("any_peer", "call_local", "reliable")
func send_attack(attacker_slot: int, target_slot: int, effect_attachments: Array[Array]) -> void:
	print("This is server...", attacker_slot, " ", target_slot, " ", effect_attachments)
	declared_attacker_slot = attacker_slot
	declared_target_slot = target_slot

	if attacker_slot == -1:
		# Skip was declared
		return

	# Merge attached effects
	for slot_num: int in effect_attachments.size():
		var effect_indexes: Array = effect_attachments[slot_num]
		attacking_player.attached_effects[slot_num].append_array(effect_indexes)
		for effect_idx: int in effect_indexes:
			attacking_player.effect_hand.erase(effect_idx)
	attack_declared.emit()


func _assign_player_ids() -> void:
	# NOTE: get_peers() does NOT include caller's own ID
	# so we need to include it manually (for the server it is 1)
	var peer_ids := [1, multiplayer.get_peers()[0]]
	# peer_ids.shuffle()
	player1.id = peer_ids[0]
	player2.id = peer_ids[1]
	_assign_client_player_number.rpc_id(player1.id, 1)
	_assign_client_player_number.rpc_id(player2.id, 2)


func _setup_player_decks() -> void:
	for entity_name in template_entity_deck:
		player1.base_entity_deck.append(CardDb.entity_cards_indexed_by_name[entity_name])
	for effect_name in template_effect_deck:
		player1.base_effect_deck.append(CardDb.effect_cards_indexed_by_name[effect_name])
	player2.base_entity_deck = player1.base_entity_deck.duplicate()
	player2.base_effect_deck = player1.base_effect_deck.duplicate()
	player1.initialize_decks()
	player2.initialize_decks()


func _draw_initial_entities() -> void:
	player1.draw_entities()
	player2.draw_entities()


@rpc("authority", "call_local", "reliable")
func _assign_client_player_number(player_number: int) -> void:
	if player_number == 1:
		controlled_player = player1
		opposing_player = player2
		(%PlayerNumberLabel as Label).text = "You are player 1"
	else:
		controlled_player = player2
		opposing_player = player1
		(%PlayerNumberLabel as Label).text = "You are player 2"


#endregion
#region CLIENT METHODS

func sync_client() -> void:
	if not multiplayer.is_server():
		await controlled_player.syncer.delta_synchronized


@rpc("authority", "call_local", "reliable")
func start_client_offense() -> void:
	await sync_client()
	button_skip.show()
	your_effect_deck.realize_effect_state()


func declare_attack(attacker_slot: int, target_slot: int) -> void:
	send_attack.rpc_id(1, attacker_slot, target_slot, queued_effect_attachments)
	queued_effect_attachments = [[], [], []]
	slot_attachment_history_stack = []
	button_skip.hide()
	button_undo.hide()


func skip_phase() -> void:
	if current_phase in [Timeline.PLAYER1_OFFENSE, Timeline.PLAYER2_OFFENSE]:
		send_attack.rpc_id(1, -1, -1, [[]])


# TODO
func enable_effect_card_dragging() -> void:
	pass


func attach_effect_to_entity_at_slot(effect_idx: int, entity_slot: int) -> void:
	var effect_card: EffectCard = controlled_player.get_effect_card_at_index(effect_idx)
	your_hand.remove_card_from_hand(effect_card)
	queued_effect_attachments[entity_slot].append(effect_idx)
	slot_attachment_history_stack.append(entity_slot)
	button_undo.show()
	arrange_attached_effects()


func undo_attachment() -> void:
	if slot_attachment_history_stack.is_empty():
		return
	
	var last_slot_used: int = slot_attachment_history_stack.pop_back()
	var last_effect_used: int = queued_effect_attachments[last_slot_used].pop_back()
	return_effect_back_to_hand(last_effect_used)
	if slot_attachment_history_stack.is_empty():
		button_undo.hide()


func arrange_attached_effects() -> void:
	const SLOT_COUNT = 3
	const CARD_SPACING = 32
	for slot_num in SLOT_COUNT:
		var preview_slot: Array = []
		preview_slot.append_array(controlled_player.attached_effects[slot_num])
		preview_slot.append_array(queued_effect_attachments[slot_num])

		for i in preview_slot.size():
			var effect_idx: int = preview_slot[i]
			var effect_card := controlled_player.get_effect_card_at_index(effect_idx)
			
			effect_card.slot_attachment_effects_enable()
			effect_card.z_index = Constants.MIN_ATTACHMENT_Z_INDEX + (i + 1)
			effect_card.detectable = false

			var target_entity := controlled_player.get_entity_card_at_slot(slot_num)
			var offset := Vector2(0, CARD_SPACING * (i + 1))
			var new_pos := target_entity.global_position + offset
			effect_card.global_position = new_pos


func return_effect_back_to_hand(effect_idx: int) -> void:
	var effect_card := controlled_player.get_effect_card_at_index(effect_idx)
	effect_card.detectable = true
	effect_card.slot_attachment_effects_disable()
	your_hand.add_card_to_hand(effect_card)


@rpc("authority", "call_local", "reliable")
func _finish_client_side_setup() -> void:
	await sync_client()
	_setup_board()
	_place_entities_on_field()


func _setup_board() -> void:
	your_entity_deck.deck_player = controlled_player
	your_entity_deck.set_deck(controlled_player.entity_deck)
	your_entity_deck.set_entity_marker_node(your_entity_markers)
	
	your_effect_deck.deck_player = controlled_player
	your_effect_deck.set_deck(controlled_player.effect_deck)
	your_effect_deck.player_hand = your_hand
	
	opp_entity_deck.deck_player = opposing_player
	opp_entity_deck.set_deck(opposing_player.entity_deck)
	opp_entity_deck.set_entity_marker_node(opp_entity_markers)
	
	opp_effect_deck.set_deck(opposing_player.effect_deck)
	opp_effect_deck.player_hand = opp_hand


func _place_entities_on_field() -> void:
	your_entity_deck.realize_entity_state()
	opp_entity_deck.realize_entity_state(true)

#endregion
