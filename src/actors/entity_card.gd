extends Card
class_name EntityCard


enum Status {
	NONE,
	POISONED,
	FROZEN,
	AGGRO,
	FATIGUED,
	RESISTANT
}

var data: EntityCardData
var max_attack: int
var max_shield: int

@export var entity_code: String
@export var current_attack: int:
	set(value):
		current_attack = value
		if _attack_label:
			_attack_label.text = str(value)
			animate_pop(_attack_label.get_parent().get_parent() as Control)


@export var current_shield: int:
	set(value):
		current_shield = value
		if _shield_label:
			_shield_label.text = str(value)
			animate_pop(_shield_label.get_parent().get_parent() as Control)
		if value <= 0:
			deactivate()

@export var status: Status = Status.NONE:
	set(value):
		status = value
		if _status_label:
			if value == Status.NONE:
				_status_label.text = ""
			else:
				_status_label.text = Status.keys()[value]

@onready var conditions: Node2D = $Conditions
@onready var _nickname: Label = %Nickname
@onready var _description: Label = %Description
@onready var _attack_label: Label = %Attack
@onready var _shield_label: Label = %Shield
@onready var _status_label: Label = %Status


func _ready() -> void:
	super._ready()
	
	data = CardDb.get_entity_by_code(entity_code)
	max_attack = data.base_attack
	max_shield = data.base_shield
	_nickname.text = data.nickname
	_description.text = data.description if data.description else "No special ability."
	_status_label.text = ""

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


func heal(amount: int) -> void:
	current_shield = min(max_shield, current_shield + amount)


func take_damage(amount: int) -> void:
	current_shield -= amount


func add_condition(condition_path: String) -> void:
	var condition: Condition = (load(condition_path) as PackedScene).instantiate()
	conditions.add_child(condition)


func get_conditions() -> Array[Condition]:
	var condition_list: Array[Condition]
	condition_list.assign(conditions.get_children())
	return condition_list


func clear_conditions() -> void:
	for condition in conditions.get_children():
		condition.queue_free()


func get_current_slot() -> int:
	return player.entities_in_play.find(current_idx)