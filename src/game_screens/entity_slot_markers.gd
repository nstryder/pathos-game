@tool
extends Node2D
class_name EntitySlotMarkers


@export var gap: int = 16:
	set(value):
		gap = value
		update_slot_positions()

@onready var is_ready: bool = true


# Hardcoding 3 slots since this requirement will never change
func update_slot_positions() -> void:
	if not is_ready:
		await ready
	($Slot1 as Marker2D).position = Vector2(gap + Constants.ENTITY_SLOT_WIDTH, 0)
	($Slot2 as Marker2D).position = Vector2.ZERO
	($Slot3 as Marker2D).position = Vector2(- (gap + Constants.ENTITY_SLOT_WIDTH), 0)
	queue_redraw()


func get_position_at_slot(slot_num: int) -> Vector2:
	return (get_child(slot_num) as Marker2D).global_position


func get_card_size() -> Vector2i:
	var card_size := Vector2i(Constants.BASE_CARD_WIDTH, Constants.BASE_CARD_HEIGHT)
	card_size *= float(Constants.ENTITY_SLOT_WIDTH) / Constants.BASE_CARD_WIDTH
	return card_size


func _draw() -> void:
	var card_size: Vector2i = get_card_size()
	var center_offset: Vector2 = card_size / 2.0
	for slot: Marker2D in get_children():
		var slot_rect := Rect2i(slot.position - center_offset, card_size)
		draw_rect(slot_rect, Color.WHITE_SMOKE, false, 2)
