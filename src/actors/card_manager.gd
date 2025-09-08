extends Node2D

@export_flags_2d_physics var collision_mask: int

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
	card_being_dragged = raycast_check_for_card()
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
	card_being_dragged = null


func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos := get_global_mouse_position()
		var screen_bounds_clamped_pos := mouse_pos.clamp(Vector2.ZERO, get_viewport_rect().size)
		card_being_dragged.global_position = screen_bounds_clamped_pos
		

func raycast_check_for_card() -> EntityCard:
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
func get_card_with_highest_z_index(cards: Array[Dictionary]) -> EntityCard:
	return cards.map(func(x: Dictionary) -> EntityCard:
		print(x.collider.owner.z_index)
		return x.collider.owner
	).reduce(func(a: EntityCard, b: EntityCard) -> EntityCard:
		return a if a.z_index > b.z_index else b
	)
