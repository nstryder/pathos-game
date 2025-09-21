extends Node2D
class_name InputManager

signal clicked
signal released

@onready var card_manager: CardManager = %CardManager
@onready var deck: Deck = %Deck


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed:
				print("clicking!")
				clicked.emit()
				raycast_at_cursor()
			else:
				released.emit()


func raycast_at_cursor() -> void:
	var space_state := get_world_2d().direct_space_state
	var parameters := PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	# parameters.collision_mask = collision_mask
	var result := space_state.intersect_point(parameters)
	if result:
		var result_node: Node2D = result.front().collider.owner
		if result_node is Card:
			var card := get_card_with_highest_z_index(result)
			card_manager.start_drag(card)
		elif result_node is Deck:
			deck.draw_card()

# Cards parameter should be from a dict returned by intersect_point()
func get_card_with_highest_z_index(cards: Array[Dictionary]) -> Card:
	return cards.map(func(x: Dictionary) -> Node2D:
		return x.collider.owner
	).filter(func(x: Node2D) -> bool:
		return x is Card
	).reduce(func(a: Card, b: Card) -> Node2D:
		return a if a.z_index > b.z_index else b
	)
