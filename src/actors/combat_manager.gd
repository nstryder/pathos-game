extends Node2D
class_name CombatManager

signal attack_declared
signal attack_rescinded

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

var declared_attacker_idx: int
var declared_target_idx: int
@export var attacking_player_nodepath: NodePath:
	set(value):
		attacking_player_nodepath = value
		if value:
			attacking_player = get_node(value)
@export var defending_player_nodepath: NodePath:
	set(value):
		defending_player_nodepath = value
		if value:
			defending_player = get_node(value)
var attacking_player: Player
var defending_player: Player

@onready var server: ServerState = %ServerState


func phase_is_offense() -> bool:
	return current_phase in [Phases.PLAYER1_OFFENSE, Phases.PLAYER2_OFFENSE]


func phase_is_defense() -> bool:
	return current_phase in [Phases.PLAYER1_DEFENSE, Phases.PLAYER2_DEFENSE]


func get_current_attacker() -> EntityCard:
	return attacking_player.get_entity_card_at_index(declared_attacker_idx)


func get_current_target() -> EntityCard:
	return defending_player.get_entity_card_at_index(declared_target_idx)


func skip_was_declared() -> bool:
	return declared_attacker_idx == -1


@rpc("authority", "call_local", "reliable")
func declare_attack(attacker_idx: int, target_idx: int) -> void:
	print(attacking_player, defending_player)
	declared_attacker_idx = attacker_idx
	declared_target_idx = target_idx
	attack_declared.emit()


@rpc("authority", "call_local", "reliable")
func rescind_attack() -> void:
	_reset_attack_indexes()
	attack_rescinded.emit()


func _reset_attack_indexes() -> void:
	declared_attacker_idx = -1
	declared_target_idx = -1


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
	var attacking_entity: EntityCard = attacking_player.get_entity_card_at_slot(declared_attacker_idx)
	var target_entity: EntityCard = defending_player.get_entity_card_at_slot(declared_target_idx)
	target_entity.current_shield -= attacking_entity.current_attack


func _resolve_deaths() -> void:
	server.player1.check_entity_deaths()
	server.player2.check_entity_deaths()
