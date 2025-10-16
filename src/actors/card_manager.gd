extends Node2D
class_name CardManager

const LAYER_EFFECT = 0b1
const LAYER_ENTITY = 0b10

var dragging_enabled: bool = false
var attacking_enabled: bool = false
var effect_card_being_dragged: EffectCard
var entity_targeting_line_visual: Line2D
var entity_card_to_declare: EntityCard

@onready var client: ClientState = %ClientState


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed:
				on_press()
			else:
				on_release()


func _process(_delta: float) -> void:
	if effect_card_being_dragged:
		var mouse_pos := get_global_mouse_position()
		var screen_bounds_clamped_pos := mouse_pos.clamp(Vector2.ZERO, get_viewport_rect().size)
		effect_card_being_dragged.global_position = screen_bounds_clamped_pos
	if entity_targeting_line_visual:
		entity_targeting_line_visual.set_point_position(1, get_global_mouse_position())


func on_press() -> void:
	if dragging_enabled:
		var effect_card := detect_effect_card()
		if effect_card and not effect_card.is_enemy:
			start_drag(effect_card)
	if attacking_enabled and not effect_card_being_dragged:
		var entity_card := detect_entity_card()
		if entity_card and not entity_card.is_enemy:
			start_declare_attack(entity_card)


func on_release() -> void:
	if effect_card_being_dragged:
		var entity_card: EntityCard = detect_entity_card()
		if entity_card and not entity_card.is_enemy:
			attach_effect_to_entity(effect_card_being_dragged, entity_card)
		else:
			reset_dragged_card_position()
			end_drag()
	elif entity_card_to_declare:
		var target_entity: EntityCard = detect_entity_card()
		if target_entity and target_entity.is_enemy:
			send_declare_attack(entity_card_to_declare, target_entity)
		end_declare_attack()


func detect_effect_card() -> EffectCard:
	return raycast_check_for_card(LAYER_EFFECT)
	

func detect_entity_card() -> EntityCard:
	return raycast_check_for_card(LAYER_ENTITY)


func attach_effect_to_entity(effect: EffectCard, entity: EntityCard) -> void:
	var effect_idx := effect.current_idx
	var entity_slot := entity.current_slot
	print("attaching effect ", effect_idx, " to slot ", entity_slot)
	client.attach_effect_to_entity_at_slot(effect_idx, entity_slot)
	effect_card_being_dragged = null


func start_drag(card: Card) -> void:
	effect_card_being_dragged = card
	effect_card_being_dragged.drag_effects_enable()


func end_drag() -> void:
	if effect_card_being_dragged:
		effect_card_being_dragged.drag_effects_disable()
	effect_card_being_dragged = null


func send_declare_attack(entity_card: EntityCard, target_entity: EntityCard) -> void:
	var attacker_slot := entity_card.current_slot
	var target_slot := target_entity.current_slot
	client.declare_attack(attacker_slot, target_slot)


func start_declare_attack(entity_card: EntityCard) -> void:
	entity_card_to_declare = entity_card
	entity_targeting_line_visual = Line2D.new()
	entity_targeting_line_visual.antialiased = true
	entity_targeting_line_visual.add_point(entity_card.global_position)
	entity_targeting_line_visual.add_point(get_global_mouse_position())
	entity_targeting_line_visual.default_color = Color8(224, 33, 33)
	add_child(entity_targeting_line_visual)


func end_declare_attack() -> void:
	entity_card_to_declare = null
	entity_targeting_line_visual.queue_free()


func reset_dragged_card_position() -> void:
	var player_hand: PlayerHand = client.your_hand
	player_hand.animate_card_to_position(effect_card_being_dragged, effect_card_being_dragged.starting_position)


func raycast_check_for_card(collision_mask: int) -> Card:
	var space_state := get_world_2d().direct_space_state
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = collision_mask
	var result := space_state.intersect_point(parameters)
	if result:
		return get_card_with_highest_z_index(result)
	else:
		return null


# Cards parameter should be from a dict returned by intersect_point()
func get_card_with_highest_z_index(cards: Array[Dictionary]) -> Card:
	return cards.map(func(x: Dictionary) -> Card:
		return x.collider.owner
	).reduce(func(a: Card, b: Card) -> Card:
		return a if a.z_index > b.z_index else b
	)
