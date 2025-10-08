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
@onready var opp_entity_deck: Deck = %OppEntityDeck
@onready var opp_effect_deck: Deck = %OppEffectDeck
@onready var opp_entity_markers: EntitySlotMarkers = %OppEntitySlotMarkers


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
	if multiplayer.is_server():
		_assign_player_ids()
		_setup_player_decks()
		_draw_initial_entities()
		_finish_client_side_setup.rpc()


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
@rpc("authority", "call_local", "reliable")
func _finish_client_side_setup() -> void:
	if not multiplayer.is_server():
		await controlled_player.syncer.delta_synchronized
	_setup_board()
	_place_entities_on_field()


func _setup_board() -> void:
	your_entity_deck.deck_player = controlled_player
	your_entity_deck.set_deck(controlled_player.entity_deck)
	your_entity_deck.set_entity_marker_node(your_entity_markers)
	
	your_effect_deck.deck_player = controlled_player
	your_effect_deck.set_deck(controlled_player.effect_deck)
	
	opp_entity_deck.deck_player = opposing_player
	opp_entity_deck.set_deck(opposing_player.entity_deck)
	opp_entity_deck.set_entity_marker_node(opp_entity_markers)
	opp_effect_deck.set_deck(opposing_player.effect_deck)


func _place_entities_on_field() -> void:
	your_entity_deck.realize_entity_state()
	opp_entity_deck.realize_entity_state()

#endregion
