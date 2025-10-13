extends Node2D
class_name BattleScreen


@export var template_entity_deck: Array[String] = []
@export var template_effect_deck: Array[String] = []


# SERVER VARS
@onready var player1: Player = $Players/Player1
@onready var player2: Player = $Players/Player2

# CLIENT VARS
var controlled_player: Player
var opposing_player: Player
@onready var your_entity_deck: Deck = %YourEntityDeck
@onready var your_effect_deck: Deck = %YourEffectDeck
@onready var your_entity_markers: EntitySlotMarkers = %YourEntitySlotMarkers
@onready var your_hand: PlayerHand = %YourHand
@onready var opp_entity_deck: Deck = %OppEntityDeck
@onready var opp_effect_deck: Deck = %OppEffectDeck
@onready var opp_entity_markers: EntitySlotMarkers = %OppEntitySlotMarkers
@onready var opp_hand: PlayerHand = %OppHand


# assign player ids
# shuffle cards
# place entities on field
# both players draw 2 fx cards


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


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


enum Timeline {
	PLAYER1_OFFENSE,
	PLAYER2_DEFENSE,
	# +1 turn
	PLAYER2_OFFENSE,
	PLAYER1_DEFENSE
	# +1 turn
}
var turn_count: int = 1
@export var current_phase: Timeline:
	set(value):
		current_phase = value
		var phase_text: String = str(Timeline.keys()[value]).capitalize()
		(%PhaseLabel as Label).text = "Current phase: " + phase_text


func start_game() -> void:
	if not multiplayer.is_server():
		return
	current_phase = Timeline.PLAYER1_OFFENSE
	check_phase()

# TODO
func check_phase() -> void:
	if current_phase == Timeline.PLAYER1_OFFENSE:
		player1.draw_effects()
		start_client_offense.rpc_id(player1.id)
		# await something..

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
	your_effect_deck.realize_effect_state()


# TODO
@rpc("any_peer", "call_local", "reliable")
func send_attack() -> void:
	pass


# TODO
func enable_effect_card_dragging() -> void:
	pass


var queued_effect_attachments: Array[Array] = [[], [], []]
var slot_attachment_history_stack: Array[int] = []


func attach_effect_to_entity_at_slot(effect_idx: int, entity_slot: int) -> void:
	var hand_idx_of_effect: int = controlled_player.effect_hand.find(effect_idx)
	controlled_player.effect_hand.remove_at(hand_idx_of_effect)
	queued_effect_attachments[entity_slot].append(effect_idx)
	slot_attachment_history_stack.append(entity_slot)
	arrange_attached_effects()

# TODO: Add undo button
func undo_attachment() -> void:
	if slot_attachment_history_stack.is_empty():
		return
	
	var last_slot_used: int = slot_attachment_history_stack.pop_back()
	var last_effect_used: int = queued_effect_attachments[last_slot_used].pop_back()
	return_effect_back_to_hand(last_effect_used)


# TODO: We need to make this look like a solitaire column
func arrange_attached_effects() -> void:
	pass
	# combine both queue and current attachments into a temp preview
	# realize this 
	# disable draggability for all attached effects


# TODO
func return_effect_back_to_hand(effect_idx: int) -> void:
	controlled_player.effect_hand.append(effect_idx)
	var effect_card := controlled_player.get_effect_card_at_index(effect_idx)
	effect_card.slot_attachment_effects_disable()
	your_hand.update_hand_positions()


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
	opp_entity_deck.realize_entity_state()

#endregion
