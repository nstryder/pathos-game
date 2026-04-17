extends Node2D
class_name Timeline

signal timeline_modified
signal discard_queue_modified

const UsageType = EffectCardData.UsageType

var _main_timeline_queue: Array[Action] = []
var _discard_queue: Array[Action] = []

class Action:
	var type: EffectCardData.UsageType
	var effect: EffectCard
	var entity: EntityCard

	static func from_dict(action_dict: Dictionary) -> Action:
		var action := Action.new()
		action.type = action_dict.type
		var effect_player_path: NodePath = action_dict.effect_player_path
		var effect_player: Player = Utils.get_node(effect_player_path)
		var effect_idx: int = action_dict.effect_idx
		action.effect = effect_player.get_effect_card_at_index(effect_idx)

		if action.type == UsageType.ATTACH:
			var entity_player_path: NodePath = action_dict.entity_player_path
			var entity_player: Player = Utils.get_node(entity_player_path)
			var entity_idx: int = action_dict.entity_idx
			action.entity = entity_player.get_entity_card_at_index(entity_idx)
		return action

	func to_dict() -> Dictionary:
		var dict := {
			type = type,
			effect_player_path = effect.player.get_path(),
			effect_idx = effect.current_idx,
		}
		if entity:
			dict.entity_player_path = effect.player.get_path()
			dict.entity_idx = entity.current_idx
		return dict


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
	assert(not _main_timeline_queue.is_empty(), "Undo was invoked on an empty timeline.")
	var last_action: Action = _main_timeline_queue.pop_back()
	var player: Player = last_action.effect.player
	player.add_effect_to_hand(last_action.effect.current_idx)
	last_action.effect.is_veiled = true
	timeline_modified.emit()


@rpc("authority", "call_local", "reliable")
func clear_timeline() -> void:
	for action in _main_timeline_queue:
		action.effect.hide_from_field()
	_main_timeline_queue.clear()
	timeline_modified.emit()


func get_queue() -> Array[Action]:
	return _main_timeline_queue

# TODO: Separate queue into immediates vs normals
func get_organized_queue() -> Array[Action]:
	return _main_timeline_queue.duplicate()


func get_queue_filtered_by_player(player: Player) -> Array[Action]:
	return _main_timeline_queue.filter(func(x: Action) -> bool: return x.effect.player == player)


func get_queue_filtered_by_entity(entity_card: EntityCard) -> Array[Action]:
	return _main_timeline_queue.filter(func(x: Action) -> bool: return x.entity == entity_card)


func get_discard_queue() -> Array[Action]:
	return _discard_queue


# The following methods are split into two parts:
#	A public method used by the server
#	A private RPC method that gets called on every client
# 	This split is necessary since Action is not serializable

	
func transfer_action_to_discard(action: Action) -> void:
	if not multiplayer.is_server():
		return
	var idx: int = _get_action_idx(action)
	_rpc_transfer_action_to_discard.rpc(idx)


@rpc("authority", "call_local", "reliable")
func _rpc_transfer_action_to_discard(action_idx: int) -> void:
	var action: Action = _main_timeline_queue[action_idx]
	_discard_queue.append(action)
	_rpc_remove_from_queue(action_idx)
	discard_queue_modified.emit()


func remove_from_queue(action: Action) -> void:
	if not multiplayer.is_server():
		return
	var idx: int = _get_action_idx(action)
	_rpc_remove_from_queue.rpc(idx)


@rpc("authority", "call_local", "reliable")
func _rpc_remove_from_queue(action_idx: int) -> void:
	_main_timeline_queue.pop_at(action_idx)
	timeline_modified.emit()


func remove_from_discard_queue(action: Action) -> void:
	if not multiplayer.is_server():
		return
	var idx: int = _discard_queue.find(action)
	assert(idx >= 0, "Attempted to get invalid action")
	_rpc_remove_from_discard_queue.rpc(idx)


@rpc("authority", "call_local", "reliable")
func _rpc_remove_from_discard_queue(action_idx: int) -> void:
	_discard_queue.pop_at(action_idx)
	discard_queue_modified.emit()


func _get_action_idx(action: Action) -> int:
	var idx: int = _main_timeline_queue.find(action)
	assert(idx >= 0, "Attempted to get invalid action")
	return idx


func _add_action_to_main_timeline(action: Action) -> void:
	_main_timeline_queue.append(action)
	timeline_modified.emit()
