extends Node2D
class_name BattleScreen


@export var template_entity_deck: Array[String] = []
@export var template_effect_deck: Array[String] = []

@onready var server_state: ServerState = %ServerState
@onready var client_state: ClientState = %ClientState

func initialize_board() -> void:
	server_state.initialize_board()
