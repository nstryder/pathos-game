extends Node2D
class_name EntityCard

@export var entity_card_data: EntityCardData

var max_attack: int
var max_shield: int
var current_attack: int
var current_shield: int

var has_shadow: bool = false:
	set(value):
		has_shadow = value
		var card_background := ($Control as Control).theme.get_stylebox("panel", "Panel") as StyleBoxFlat
		if has_shadow:
			card_background.shadow_size = 6
		else:
			card_background.shadow_size = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not entity_card_data:
		return
	max_attack = entity_card_data.base_attack
	max_shield = entity_card_data.base_shield
	current_attack = max_attack
	current_shield = max_shield
