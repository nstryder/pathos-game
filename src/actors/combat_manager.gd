extends Node2D
class_name CombatManager


enum Phases {
	PLAYER1_OFFENSE,
	PLAYER2_DEFENSE,
	# +1 turn
	PLAYER2_OFFENSE,
	PLAYER1_DEFENSE,
	# +1 turn
	COMBAT,
	NEUTRAL
}

var turn_count: int = 0
@export var current_phase: Phases = Phases.NEUTRAL:
	set(value):
		current_phase = value
		var phase_text: String = str(Phases.keys()[value]).capitalize()
		(%PhaseLabel as Label).text = "Current phase: " + phase_text

@export var declared_attacker_slot: int
@export var declared_target_slot: int

var attacking_player: Player
var defending_player: Player

@onready var server: ServerState = %ServerState


func phase_is_offense() -> bool:
	return current_phase in [Phases.PLAYER1_OFFENSE, Phases.PLAYER2_OFFENSE]


func phase_is_defense() -> bool:
	return current_phase in [Phases.PLAYER1_DEFENSE, Phases.PLAYER2_DEFENSE]


func skip_was_declared() -> bool:
	return declared_attacker_slot == -1


# TODO
func player_has_won() -> bool:
	return false


func start_combat() -> void:
	_resolve_effects()
	_resolve_combat()
	_resolve_deaths()

# TODO
func _resolve_effects() -> void:
	pass


func _resolve_combat() -> void:
	var attacking_entity: EntityCard = attacking_player.get_entity_card_at_slot(declared_attacker_slot)
	var target_entity: EntityCard = defending_player.get_entity_card_at_slot(declared_target_slot)
	target_entity.current_shield -= attacking_entity.current_attack


func _resolve_deaths() -> void:
	server.player1.check_entity_deaths()
	server.player2.check_entity_deaths()
