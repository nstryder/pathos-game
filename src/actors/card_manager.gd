extends Node2D

const COLLISION_MASK_CARD = 0b1
const COLLISION_MASK_SLOT = 0b10

var card_being_dragged: EntityCard
var last_card_dragged: EntityCard

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed:
				start_drag()
			else:
				end_drag()

	
func start_drag() -> void:
	card_being_dragged = raycast_check_for_card(COLLISION_MASK_CARD)
	if last_card_dragged:
		last_card_dragged.z_index = 1
	if card_being_dragged:
		card_being_dragged.z_index = 2
		card_being_dragged.has_shadow = true
		card_being_dragged.scale = Vector2.ONE * 1.05
	last_card_dragged = card_being_dragged


func end_drag() -> void:
	if card_being_dragged:
		card_being_dragged.has_shadow = false
		card_being_dragged.scale = Vector2.ONE
		var card_slot_found: CardSlot = raycast_check_for_card(COLLISION_MASK_SLOT)
		if card_slot_found and not card_slot_found.card_is_in_slot:
			card_being_dragged.global_position = card_slot_found.global_position
			card_being_dragged.draggable = false
			card_slot_found.card_is_in_slot = true
	card_being_dragged = null


func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos := get_global_mouse_position()
		var screen_bounds_clamped_pos := mouse_pos.clamp(Vector2.ZERO, get_viewport_rect().size)
		card_being_dragged.global_position = screen_bounds_clamped_pos
		

func raycast_check_for_card(collision_mask: int) -> Node2D:
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
func get_card_with_highest_z_index(cards: Array[Dictionary]) -> Node2D:
	return cards.map(func(x: Dictionary) -> Node2D:
		print(x.collider.owner.z_index)
		return x.collider.owner
	).reduce(func(a: Node2D, b: Node2D) -> Node2D:
		return a if a.z_index > b.z_index else b
	)
