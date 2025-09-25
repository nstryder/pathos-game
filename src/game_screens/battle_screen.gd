extends Node2D
class_name BattleScreen

@export var template_entity_deck: Array[String] = []
@export var template_effect_deck: Array[String] = []

	
# SERVER VARS
@onready var player1: Player = $Players/Player1
@onready var player2: Player = $Players/Player2

# CLIENT VARS
var seated_as_player_number: int


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


# SERVER METHODS
func initialize_board() -> void:
	if multiplayer.is_server():
		_assign_player_ids()
		_setup_player_decks()


func _assign_player_ids() -> void:
	# NOTE: get_peers() does NOT include caller's own ID
	# so we need to include it manually (for the server it is 1)
	var peer_ids := [1, multiplayer.get_peers()[0]]
	peer_ids.shuffle()
	player1.id = peer_ids[0]
	player2.id = peer_ids[1]


func _setup_player_decks() -> void:
	for entity_name in template_entity_deck:
		player1.base_entity_deck.append(CardDb.entity_cards_indexed_by_name[entity_name])
	for effect_name in template_effect_deck:
		player1.base_effect_deck.append(CardDb.effect_cards_indexed_by_name[effect_name])
	player2.base_entity_deck = player1.base_entity_deck.duplicate()
	player2.base_effect_deck = player1.base_effect_deck.duplicate()
	player1.initialize_decks()
	player2.initialize_decks()
	
# CLIENT METHODS
