extends Node2D
class_name Timeline

signal timeline_modified

const UsageType = EffectCardData.UsageType

var immediate_queue: Array[Dictionary] = []
var main_timeline_queue: Array[Action] = []

class Action:
	var type: EffectCardData.UsageType
	var effect: EffectCard
	var entity: EntityCard


@rpc("any_peer", "call_local", "reliable")
func register_effect_attachment(owner_player_path: NodePath, effect_idx: int, target_player_path: NodePath, target_entity_idx: int) -> void:
	print("Attaching FX...")
	var action := Action.new()

	var player: Player = %Players.get_node(owner_player_path)
	var target_player: Player = %Players.get_node(target_player_path)

	action.type = UsageType.ATTACH
	action.effect = player.get_effect_card_at_index(effect_idx)
	action.entity = target_player.get_entity_card_at_index(target_entity_idx)

	player.remove_effect_from_hand(effect_idx)
	action.effect.is_veiled = false
	_add_action_to_main_timeline(action)


@rpc("any_peer", "call_local", "reliable")
func register_effect_use(owner_player_path: NodePath, effect_idx: int) -> void:
	print("Using FX...")
	var action := Action.new()
	var player: Player = %Players.get_node(owner_player_path)
	
	action.type = UsageType.USE
	action.effect = player.get_effect_card_at_index(effect_idx)

	player.remove_effect_from_hand(effect_idx)
	action.effect.hide_from_field()
	_add_action_to_main_timeline(action)


@rpc("any_peer", "call_local", "reliable")
func undo() -> void:
	assert(not main_timeline_queue.is_empty(), "Undo was invoked on an empty timeline.")
	var last_action: Action = main_timeline_queue.pop_back()
	var player: Player = last_action.effect.player
	player.add_effect_to_hand(last_action.effect.current_idx)
	last_action.effect.is_veiled = true
	timeline_modified.emit()


@rpc("authority", "call_local", "reliable")
func clear_timeline() -> void:
	for action in main_timeline_queue:
		action.effect.hide_from_field()
	main_timeline_queue.clear()
	timeline_modified.emit()


func get_queue_filtered_by_player(player: Player) -> Array[Action]:
	return main_timeline_queue.filter(func(x: Action) -> bool: return x.effect.player == player)


func _add_action_to_main_timeline(action: Action) -> void:
	main_timeline_queue.append(action)
	timeline_modified.emit()
