extends Card
class_name EntityCard

@export var entity_code: String
var data: EntityCardData


var max_attack: int
var max_shield: int
@export var current_attack: int:
	set(value):
		current_attack = value
		if attack_label:
			attack_label.text = str(value)
			animate_pop(attack_label.get_parent().get_parent() as Control)
@export var current_shield: int:
	set(value):
		current_shield = value
		if shield_label:
			shield_label.text = str(value)
			animate_pop(shield_label.get_parent().get_parent() as Control)
		if value <= 0:
			deactivate()

@onready var nickname: Label = %Nickname
@onready var description: Label = %Description
@onready var attack_label: Label = %Attack
@onready var shield_label: Label = %Shield

var current_slot: int:
	get:
		return player.entities_in_play.find(current_idx)


func _ready() -> void:
	super._ready()
	
	data = CardDb.get_entity_by_code(entity_code)
	max_attack = data.base_attack
	max_shield = data.base_shield
	nickname.text = data.nickname

	Utils.validate_vars(self , entity_code, data)


func activate() -> void:
	modulate = Color(1, 1, 1, 1)
	current_attack = max_attack
	current_shield = max_shield


func deactivate() -> void:
	modulate = Color(1, 1, 1, 0.5)


func animate_pop(node: Control) -> void:
	node.pivot_offset = node.size / 2
	var scale_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	scale_tween.tween_property(node, "scale", Vector2.ONE * 3, 0.1)
	scale_tween.tween_property(node, "scale", Vector2.ONE, 0.1)

	var rot_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rot_tween.tween_property(node, "rotation", PI / 6.0, 0.1)
	rot_tween.tween_property(node, "rotation", -PI / 6.0, 0.1)
	rot_tween.tween_property(node, "rotation", 0, 0.1)
