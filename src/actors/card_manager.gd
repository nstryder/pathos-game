extends Node2D
class_name CardManager

signal use_fx_dragged
signal use_fx_released

const LAYER_EFFECT = 0b1
const LAYER_ENTITY = 0b10
const LAYER_USE = 0b100

const Status = EntityCard.Status

var dragging_enabled: bool = false
var attacking_enabled: bool = false

var _effect_card_being_dragged: EffectCard
var _entity_targeting_line_visual: Line2D
var _entity_card_to_declare: EntityCard

@onready var client: ClientState = %ClientState


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed:
				_on_press()
			else:
				_on_release()


func _process(_delta: float) -> void:
	if _effect_card_being_dragged:
		var mouse_pos := get_global_mouse_position()
		var screen_bounds_clamped_pos := mouse_pos.clamp(Vector2.ZERO, get_viewport_rect().size)
		_effect_card_being_dragged.global_position = screen_bounds_clamped_pos
	if _entity_targeting_line_visual:
		_entity_targeting_line_visual.set_point_position(1, get_global_mouse_position())


func _on_press() -> void:
	if dragging_enabled:
		var effect_card := _detect_effect_card()
		if effect_card and not _is_enemy_card(effect_card):
			_drag_effect(effect_card)
	if attacking_enabled and not _effect_card_being_dragged:
		_drag_entity()


func _drag_effect(effect_card: EffectCard) -> void:
	_effect_card_being_dragged = effect_card
	_effect_card_being_dragged.drag_effects_enable()
	if effect_card.data.usage_type == EffectCardData.UsageType.USE:
		use_fx_dragged.emit()


func _drag_entity() -> void:
	var entity_card := _detect_entity_card()
	if entity_card and not _is_enemy_card(entity_card) and entity_card.status != Status.FROZEN:
		_start_declare_attack(entity_card)


func _on_release() -> void:
	if _effect_card_being_dragged:
		if _effect_card_being_dragged.data.usage_type == EffectCardData.UsageType.USE:
			_release_use_effect()
		else:
			_release_attach_effect()
	elif _entity_card_to_declare:
		var target_entity: EntityCard = _detect_entity_card()
		if target_entity and _is_enemy_card(target_entity):
			var aggro_prevents_attack: bool = target_entity.player.has_aggro() and target_entity.status != Status.AGGRO
			if not aggro_prevents_attack:
				_send_declare_attack(_entity_card_to_declare, target_entity)
		elif client.combat_manager.attack_is_declared():
			client.rescind_attack()
		_end_declare_attack()


func _release_use_effect() -> void:
	var wants_to_use: bool = _detect_fx_use_box()
	if wants_to_use:
		client.use_effect(_effect_card_being_dragged)
	else:
		_reset_dragged_card_position()
	_effect_card_being_dragged = null
	use_fx_released.emit()


func _release_attach_effect() -> void:
	var entity_card: EntityCard = _detect_entity_card()
	if not entity_card:
		_reset_dragged_card_position()
		_effect_card_being_dragged = null
		return
	
	if _can_attach(entity_card):
		client.attach_effect_to_entity(_effect_card_being_dragged, entity_card)
	else:
		_reset_dragged_card_position()
	
	_effect_card_being_dragged = null


func _can_attach(entity_card: EntityCard) -> bool:
	var effect_data := _effect_card_being_dragged.data

	var status_prevents_attach := entity_card.status in [Status.FATIGUED, Status.FROZEN]
	if status_prevents_attach: return false

	var already_has_status := (effect_data.identifier == EffectCardData.Identifier.STATUS and entity_card.status != Status.NONE)
	if already_has_status: return false

	var already_has_aggro := (effect_data.effect_name == "Taunt" and entity_card.player.has_aggro())
	if already_has_aggro: return false

	for action in client.server.timeline.get_queue_filtered_by_entity(entity_card):
		if action.effect.data.identifier == EffectCardData.Identifier.STATUS:
			return false

	return true


func _detect_effect_card() -> EffectCard:
	return _raycast_check_for_card(LAYER_EFFECT)
	

func _detect_entity_card() -> EntityCard:
	return _raycast_check_for_card(LAYER_ENTITY)


func _detect_fx_use_box() -> bool:
	# Have to use Ray instead of Point for this
	# Why? Because Godot currently has a bug with points vs shapes in CanvasLayers
	# Relevant issue: https://github.com/godotengine/godot/issues/105068
	var space_state := get_world_2d().direct_space_state
	var parameters := PhysicsRayQueryParameters2D.new()
	parameters.from = get_global_mouse_position()
	parameters.to = parameters.from
	parameters.hit_from_inside = true
	parameters.collide_with_areas = true
	parameters.collision_mask = LAYER_USE
	var result := space_state.intersect_ray(parameters)
	print(result)
	return not result.is_empty()


func _send_declare_attack(entity_card: EntityCard, target_entity: EntityCard) -> void:
	client.declare_attack(entity_card, target_entity)


func _start_declare_attack(entity_card: EntityCard) -> void:
	_entity_card_to_declare = entity_card
	_entity_targeting_line_visual = Line2D.new()
	_entity_targeting_line_visual.antialiased = true
	_entity_targeting_line_visual.add_point(entity_card.global_position)
	_entity_targeting_line_visual.add_point(get_global_mouse_position())
	_entity_targeting_line_visual.default_color = Color8(224, 33, 33)
	add_child(_entity_targeting_line_visual)


func _end_declare_attack() -> void:
	_entity_card_to_declare = null
	_entity_targeting_line_visual.queue_free()


func _reset_dragged_card_position() -> void:
	var player_hand: PlayerHand = client.your_side.hand
	player_hand.animate_card_to_position(_effect_card_being_dragged, _effect_card_being_dragged.starting_position)
	_effect_card_being_dragged.drag_effects_disable()


func _raycast_check_for_card(collision_mask: int) -> Card:
	var space_state := get_world_2d().direct_space_state
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = collision_mask
	var result := space_state.intersect_point(parameters)
	if result:
		return _get_card_with_highest_z_index(result)
	else:
		return null


func _is_enemy_card(card: Card) -> bool:
	return card.player != client.controlled_player


# Cards parameter should be from a dict returned by intersect_point()
func _get_card_with_highest_z_index(cards: Array[Dictionary]) -> Card:
	return cards.map(func(x: Dictionary) -> Card:
		return x.collider.owner
	).reduce(func(a: Card, b: Card) -> Card:
		return a if a.z_index > b.z_index else b
	)
