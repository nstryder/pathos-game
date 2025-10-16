extends Node2D
class_name CombatManager


enum Timeline {
	PLAYER1_OFFENSE,
	PLAYER2_DEFENSE,
	# +1 turn
	PLAYER2_OFFENSE,
	PLAYER1_DEFENSE,
	# +1 turn
	NEUTRAL
}

var turn_count: int = 1
@export var current_phase: Timeline = Timeline.NEUTRAL:
	set(value):
		current_phase = value
		var phase_text: String = str(Timeline.keys()[value]).capitalize()
		(%PhaseLabel as Label).text = "Current phase: " + phase_text

@export var declared_attacker_slot: int
@export var declared_target_slot: int

var attacking_player: Player
var defending_player: Player

@onready var battle_screen: BattleScreen = owner


func phase_is_offense() -> bool:
	return current_phase in [Timeline.PLAYER1_OFFENSE, Timeline.PLAYER2_OFFENSE]


func phase_is_defense() -> bool:
	return current_phase in [Timeline.PLAYER1_DEFENSE, Timeline.PLAYER2_DEFENSE]


func resolve_combat() -> void:
	pass


# TODO
func resolve_deaths() -> void:
	pass


# TODO
func player_has_won() -> bool:
	return false