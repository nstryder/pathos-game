extends Node2D
class_name CardManager

const COLLISION_MASK_CARD = 0b1
const COLLISION_MASK_SLOT = 0b10
const SLOT_SCALE = 0.6

var card_being_dragged: Card
var last_card_dragged: Card

@onready var player_hand: PlayerHand = %PlayerHand
@onready var input_manager: InputManager = %InputManager
@onready var card_slots: Node2D = %CardSlots
@onready var card_slot_positions: Control = %CardSlotPositions


func _ready() -> void:
	input_manager.released.connect(_on_input_manager_released)
	# Need to await because containers only calculate at end of frame
	await get_tree().process_frame
	for slot_container: Control in card_slot_positions.get_children():
		var slot_position := (slot_container.get_child(0) as Control
			).global_position
		const card_slot_scene := preload("uid://c1t6j0a6ap1jc")
		var card_slot: CardSlot = card_slot_scene.instantiate()
		card_slots.add_child(card_slot)
		card_slot.position = slot_position
		card_slot.scale *= SLOT_SCALE


func start_drag(card: Card) -> void:
	card_being_dragged = card
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
			player_hand.remove_card_from_hand(card_being_dragged)
			card_being_dragged.global_position = card_slot_found.global_position
			card_being_dragged.scale *= SLOT_SCALE
			card_being_dragged.draggable = false
			card_slot_found.card_is_in_slot = true
		else:
			player_hand.animate_card_to_position(card_being_dragged, card_being_dragged.starting_position)
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


func _on_input_manager_released() -> void:
	if card_being_dragged:
		end_drag()
