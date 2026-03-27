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


func attack_is_declared() -> bool:
	return declared_attacker_idx != -1


@rpc("authority", "call_local", "reliable")
func declare_attack(attacker_idx: int, target_idx: int) -> void:
	declared_attacker_idx = attacker_idx
	declared_target_idx = target_idx
	attack_declared.emit()


@rpc("authority", "call_local", "reliable")
func rescind_attack() -> void:
	reset_attack_indexes()
	attack_rescinded.emit()


@rpc("authority", "call_local", "reliable")
func reset_attack_indexes() -> void:
	declared_attacker_idx = -1
	declared_target_idx = -1


# TODO
func player_has_won() -> bool:
	return false


func start_combat() -> void:
	if not multiplayer.is_server():
		return
	
	await _resolve_effects()
	if attack_is_declared():
		await _resolve_combat()
	await _resolve_discards()
	await _resolve_deaths()


func _resolve_effects() -> void:
	server.client.set_status.rpc("Resolving Effects...")
	for action: Timeline.Action in server.timeline.get_organized_queue():
		var game_data := _create_game_data(action)
		action.effect.behavior.enter(game_data)

		if action.effect.data.usage_type == EffectCardData.UsageType.ATTACH:
			server.timeline.transfer_action_to_discard(action)
		else:
			server.timeline.remove_from_queue(action)
		server.client.visualize_combat_phase_fx.rpc(action.to_dict())
		await Utils.sleep(1)
	await Utils.sleep(1)


func _resolve_combat() -> void:
	server.client.visualize_combat.rpc()
	var attacker: EntityCard = get_current_attacker()
	var defender: EntityCard = get_current_target()

	# TODO: Implement damage formula hijacking
	defender.current_shield -= attacker.current_attack

	for condition in attacker.get_conditions():
		condition.on_post_damage_given(attacker, defender)
	
	attacker.clear_conditions()
	defender.clear_conditions()
	await Utils.sleep(1)
		

func _resolve_discards() -> void:
	server.client.set_status.rpc("Discarding cards...")
	for action: Timeline.Action in server.timeline.get_discard_queue():
		if action.effect.data.usage_type == EffectCardData.UsageType.ATTACH:
			var game_data := _create_game_data(action)
			action.effect.behavior.exit(game_data)
			server.timeline.remove_from_discard_queue(action)
	await Utils.sleep(1)


func _resolve_deaths() -> void:
	server.client.set_status.rpc("Checking deaths...")
	server.player1.check_entity_deaths()
	server.player2.check_entity_deaths()
	await Utils.sleep(1)


func _create_game_data(action: Timeline.Action) -> EffectBehavior.GameData:
	var game_data := EffectBehavior.GameData.new()
	game_data.effect_player = action.effect.player
	game_data.target_entity = action.entity
	game_data.server = server
	return game_data