extends Node2D
class_name Card

@export var current_idx: int
var is_enemy: bool = false
var starting_position: Vector2
var player: Player

var detectable: bool = true:
	set(value):
		detectable = value
		($Area2D/CollisionShape2D as CollisionShape2D).disabled = !value


var has_shadow: bool = false:
	set(value):
		has_shadow = value
		# var card_background := (%Background as Control).theme.get_stylebox("panel", "Panel") as StyleBoxFlat
		var card_background: StyleBoxFlat = (%Background as Control)["theme_override_styles/panel"]
		if has_shadow:
			card_background.shadow_size = 6
		else:
			card_background.shadow_size = 0


var is_veiled: bool = false:
	set(value):
		if is_revealed_permanently:
			is_veiled = false
		else:
			is_veiled = value
		(%Veil as Control).visible = is_veiled


var is_revealed_permanently: bool = false:
	set(value):
		is_revealed_permanently = value
		if value:
			is_veiled = true


func _ready() -> void:
	player = get_parent().get_parent()
	Utils.validate_vars(self, player, current_idx)


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
	position = Vector2.ZERO
