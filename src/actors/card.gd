extends Node2D
class_name Card

var starting_position: Vector2
var current_idx: int
var is_enemy: bool = false

var detectable: bool = true:
	set(value):
		detectable = value
		($Area2D/CollisionShape2D as CollisionShape2D).disabled = !value


var has_shadow: bool = false:
	set(value):
		has_shadow = value
		var card_background := ($Control as Control).theme.get_stylebox("panel", "Panel") as StyleBoxFlat
		if has_shadow:
			card_background.shadow_size = 6
		else:
			card_background.shadow_size = 0


func drag_effects_enable() -> void:
	z_index = 2
	has_shadow = true
	scale = Vector2.ONE * 1.05


func drag_effects_disable() -> void:
	z_index = 2
	has_shadow = true
	scale = Vector2.ONE * 1.05


func slot_attachment_effects_enable() -> void:
	scale = Vector2.ONE * Constants.ENTITY_SCALE
	z_index = Constants.MIN_ATTACHMENT_Z_INDEX


func slot_attachment_effects_disable() -> void:
	scale = Vector2.ONE
	z_index = 0


@rpc("authority", "call_local", "reliable")
func hide_from_field() -> void:
	global_position = Vector2() * 500