extends Node2D
class_name BattleScreen

signal attack_declared
signal defense_declared

const SLOT_COUNT = 3
const CARD_SPACING = 32

enum Timeline {
	PLAYER1_OFFENSE,
	PLAYER2_DEFENSE,
	# +1 turn
	PLAYER2_OFFENSE,
	PLAYER1_DEFENSE,
	# +1 turn
	NEUTRAL
}

@export var template_entity_deck: Array[String] = []
@export var template_effect_deck: Array[String] = []


# SERVER VARS
var turn_count: int = 1
@export var current_phase: Timeline = Timeline.NEUTRAL:
	set(value):
		current_phase = value
		var phase_text: String = str(Timeline.keys()[value]).capitalize()
		(%PhaseLabel as Label).text = "Current phase: " + phase_text

var attacking_player: Player
var defending_player: Player
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
@onready var button_confirm: Button = %ConfirmButton
@onready var card_manager: CardManager = %CardManager
@onready var attack_indicator: Line2D = %AttackIndicator
@onready var server_state_syncer: MultiplayerSynchronizer = %ServerStateSynchronizer


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
	button_confirm.hide()
	button_confirm.pressed.connect(declare_defense)
	set_status('')


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
	if multiplayer.is_server():
		start_timeline()

# TODO
func start_timeline() -> void:
	current_phase = Timeline.PLAYER1_OFFENSE
	player1.draw_effects()
	attacking_player = player1
	start_client_offense.rpc_id(player1.id)
	wait_for_turn.rpc_id(player2.id)
	await attack_declared

	current_phase = Timeline.PLAYER2_DEFENSE
	start_client_defense.rpc_id(player2.id)
	await defense_declared
		
		
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
		attack_declared.emit()
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

func client_sync_player_state() -> void:
	if not multiplayer.is_server():
		await controlled_player.syncer.delta_synchronized


func client_sync_server_state() -> void:
	if not multiplayer.is_server():
		await server_state_syncer.delta_synchronized


func start_turn() -> void:
	set_status('')


@rpc("authority", "call_local", "reliable")
func wait_for_turn() -> void:
	set_status("Waiting for opponent's action...")
	card_manager.dragging_enabled = false
	card_manager.attacking_enabled = false


func set_status(text: String) -> void:
	(%StatusLabel as Label).text = text


func show_attack_indicator(from: Vector2, to: Vector2) -> void:
	attack_indicator.show()
	attack_indicator.set_point_position(0, from)
	attack_indicator.set_point_position(1, to)


func show_attack_indicator_via_players(attacker_player: Player, target_player: Player, attacker_slot: int, target_slot: int) -> void:
	var attacker_pos := attacker_player.get_entity_card_at_slot(attacker_slot).global_position
	var target_pos := target_player.get_entity_card_at_slot(target_slot).global_position
	show_attack_indicator(attacker_pos, target_pos)


@rpc("authority", "call_local", "reliable")
func start_client_offense() -> void:
	await client_sync_server_state()
	start_turn()
	card_manager.dragging_enabled = true
	card_manager.attacking_enabled = true
	button_skip.show()
	button_undo.hide()
	reset_queued_attachments()
	your_effect_deck.realize_effect_state()


func end_client_offense() -> void:
	reset_queued_attachments()
	button_skip.hide()
	button_undo.hide()
	wait_for_turn()


@rpc("authority", "call_local", "reliable")
func start_client_defense() -> void:
	await client_sync_server_state()
	start_turn()
	card_manager.dragging_enabled = true
	card_manager.attacking_enabled = false
	show_attack_indicator_via_players(opposing_player, controlled_player, declared_attacker_slot, declared_target_slot)
	arrange_attached_effects(opposing_player, opposing_player.attached_effects)
	button_skip.show()
	button_undo.hide()
	button_confirm.hide()
	reset_queued_attachments()
	

func end_client_defense() -> void:
	reset_queued_attachments()
	button_skip.hide()
	button_undo.hide()
	button_confirm.hide()
	wait_for_turn()


func declare_attack(attacker_slot: int, target_slot: int) -> void:
	send_attack.rpc_id(1, attacker_slot, target_slot, queued_effect_attachments)
	show_attack_indicator_via_players(controlled_player, opposing_player, attacker_slot, target_slot)
	end_client_offense()


# TODO
func declare_defense() -> void:
	pass


func skip_phase() -> void:
	if current_phase in [Timeline.PLAYER1_OFFENSE, Timeline.PLAYER2_OFFENSE]:
		declare_attack(-1, -1)
	else:
		declare_defense()


func reset_queued_attachments() -> void:
	queued_effect_attachments = [[], [], []]
	slot_attachment_history_stack = []


func attach_effect_to_entity_at_slot(effect_idx: int, entity_slot: int) -> void:
	var effect_card: EffectCard = controlled_player.get_effect_card_at_index(effect_idx)
	your_hand.remove_card_from_hand(effect_card)
	queued_effect_attachments[entity_slot].append(effect_idx)
	slot_attachment_history_stack.append(entity_slot)
	if current_phase in [Timeline.PLAYER1_DEFENSE, Timeline.PLAYER2_DEFENSE]:
		button_confirm.show()
	button_undo.show()
	button_skip.hide()
	var preview_attachments := build_preview_attachments()
	arrange_attached_effects(controlled_player, preview_attachments)


func undo_attachment() -> void:
	if slot_attachment_history_stack.is_empty():
		return
	
	var last_slot_used: int = slot_attachment_history_stack.pop_back()
	var last_effect_used: int = queued_effect_attachments[last_slot_used].pop_back()
	return_effect_back_to_hand(last_effect_used)
	if slot_attachment_history_stack.is_empty():
		button_skip.show()
		button_undo.hide()
		button_confirm.hide()


func build_preview_attachments() -> Array[Array]:
	var preview_attachments: Array[Array] = [[], [], []]
	for slot_num in SLOT_COUNT:
		var preview_slot: Array = []
		preview_slot.append_array(controlled_player.attached_effects[slot_num])
		preview_slot.append_array(queued_effect_attachments[slot_num])
		preview_attachments[slot_num] = preview_slot
	return preview_attachments


func arrange_attached_effects(from_player: Player, attachments: Array[Array]) -> void:
	for slot_num in SLOT_COUNT:
		var slot_attachments: Array = attachments[slot_num]
		for i in slot_attachments.size():
			var effect_idx: int = slot_attachments[i]
			var effect_card := from_player.get_effect_card_at_index(effect_idx)
			
			effect_card.slot_attachment_effects_enable()
			effect_card.z_index = Constants.MIN_ATTACHMENT_Z_INDEX + (i + 1)
			effect_card.detectable = false

			var target_entity := from_player.get_entity_card_at_slot(slot_num)
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
	await client_sync_player_state()
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
