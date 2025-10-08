extends Node2D
class_name Card

var starting_position: Vector2

var draggable: bool = true:
	set(value):
		draggable = value
		($Area2D/CollisionShape2D as CollisionShape2D).disabled = !value


var has_shadow: bool = false:
	set(value):
		has_shadow = value
		var card_background := ($Control as Control).theme.get_stylebox("panel", "Panel") as StyleBoxFlat
		if has_shadow:
			card_background.shadow_size = 6
		else:
			card_background.shadow_size = 0


@rpc("authority", "call_local", "reliable")
func hide_from_field() -> void:
	global_position = Vector2() * 500