extends Node2D
class_name CombatManager

signal attack_declared
signal attack_rescinded


class EntityCombatData:
	var hit_player_instead: bool = false


class PlayerCombatData:
	var damage_modifier: float = 1.0
	var overdamage_modifier: float = 1.0


class CombatData:
	var entities: Dictionary[EntityCard, EntityCombatData] = {}
	var players: Dictionary[Player, PlayerCombatData] = {}

	
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
var combat_data: CombatData

@onready var server: ServerState = %ServerState

#region STATE UTILS
func phase_is_offense() -> bool:
	return current_phase in [Phases.PLAYER1_OFFENSE, Phases.PLAYER2_OFFENSE]


func phase_is_defense() -> bool:
	return current_phase in [Phases.PLAYER1_DEFENSE, Phases.PLAYER2_DEFENSE]


func get_current_attacker() -> EntityCard:
	assert(attacking_player != null, "Attacker is not set yet.")
	return attacking_player.get_entity_card_at_index(declared_attacker_idx)


func get_current_target() -> EntityCard:
	assert(defending_player != null, "Defender is not set yet.")
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


#endregion
#region DAMAGE CALCULATION

## Use this in most cases when an Entity is trying to attack another Entity
## whether a direct attack or through its ability
func deal_damage(attacker: EntityCard, target: EntityCard, amount: int) -> void:
	var damage_modifier: float = combat_data.players[target.player].damage_modifier
	var damage := int(amount * damage_modifier)
	if combat_data.entities[attacker].hit_player_instead:
		deal_player_damage(target.player, damage)
	else:
		target.take_damage(damage)


## Use this for cases when you are dealing damage from non-entity sources
## For example Mortar
func deal_global_damage(target: EntityCard, amount: int) -> void:
	var damage_modifier: float = combat_data.players[target.player].damage_modifier
	var damage := int(amount * damage_modifier)
	target.take_damage(damage)


## Use this when the player needs to take damage
func deal_player_damage(player: Player, amount: int) -> void:
	player.take_damage(amount)


func get_all_active_entities() -> Array[EntityCard]:
	return server.player1.get_all_entities_in_play() + server.player2.get_all_entities_in_play()


func get_all_revealed_entities() -> Array[EntityCard]:
	return get_all_active_entities().filter(func(x: EntityCard) -> bool:
		return x.is_revealed == true
	)


#endregion
#region COMBAT RESOLUTION


func resolve_turn_start() -> void:
	_initialize_combat_data()
	for entity in get_all_active_entities():
		match entity.status:
			EntityCard.Status.POISONED:
				deal_global_damage(entity, 1)
			EntityCard.Status.FROZEN, EntityCard.Status.RESISTANT:
				entity.status = EntityCard.Status.NONE
		
		
func start_combat() -> void:
	if not multiplayer.is_server():
		return
	
	await _resolve_effects()
	if attack_is_declared():
		await _resolve_abilities()
		await _resolve_combat()
	await _resolve_discards()
	await _resolve_deaths()


func _initialize_combat_data() -> void:
	combat_data = CombatData.new()
	var all_active_entities: Array[EntityCard] = get_all_active_entities()
	for entity in all_active_entities:
		var entity_data := EntityCombatData.new()
		combat_data.entities[entity] = entity_data
	
	combat_data.players[server.player1] = PlayerCombatData.new()
	combat_data.players[server.player2] = PlayerCombatData.new()
	print("Combat Data inited: ", combat_data.players)
	

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


func _resolve_abilities() -> void:
	server.client.set_status.rpc("Resolving Abilities...")

	var attacker: EntityCard = get_current_attacker()
	var defender: EntityCard = get_current_target()

	var ability_game_data := EntityAbility.GameData.new()
	ability_game_data.server = server
	ability_game_data.combat_data = combat_data

	attacker.ability.activate(ability_game_data)
	defender.ability.activate(ability_game_data)

	await Utils.sleep(1)


func _resolve_combat() -> void:
	server.client.visualize_combat.rpc()

	var attacker: EntityCard = get_current_attacker()
	var defender: EntityCard = get_current_target()

	deal_damage(attacker, defender, attacker.current_attack)

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
	for player: Player in [attacking_player, defending_player]:
		for entity in player.get_all_entities_in_play():
			if entity.current_shield <= 0:
				print("Removing entity from play: ", entity.data.nickname)
				var overdamage: int = abs(entity.current_shield) * combat_data.players[player].overdamage_modifier
				deal_player_damage(player, 2 + overdamage)
				player.remove_entity_from_play(entity.current_idx)
				player.send_entity_to_graveyard(entity.current_idx)
				player.draw_entities()
	await get_tree().process_frame
	server.client.update_entities_on_field.rpc()
	await Utils.sleep(1)


func _create_game_data(action: Timeline.Action) -> EffectBehavior.GameData:
	var game_data := EffectBehavior.GameData.new()
	game_data.effect_player = action.effect.player
	game_data.target_entity = action.entity
	game_data.server = server
	game_data.combat_data = combat_data
	return game_data


#endregion
