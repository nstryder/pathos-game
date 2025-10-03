extends Node2D
class_name LobbyScreen


@onready var battle_screen: BattleScreen = $BattleScreen


func start_game() -> void:
	($ConnectLayer as CanvasLayer).hide()
	if multiplayer.is_server():
		battle_screen.initialize_board()
