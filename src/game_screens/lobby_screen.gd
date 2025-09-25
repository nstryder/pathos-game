extends Node2D
class_name LobbyScreen


@onready var battle_screen: BattleScreen = $BattleScreen


func start_game() -> void:
    if not multiplayer.is_server(): return
    battle_screen.initialize_board()