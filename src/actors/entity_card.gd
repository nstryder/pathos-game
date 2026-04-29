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
var ability: EntityAbility

@export var entity_code: String

@export var is_amped: bool = false:
	set(value):
		is_amped = value
		if value == true:
			modulate = Color.YELLOW
			if _description:
				_description.text = data.amp_description
		else:
			modulate = Color.WHITE
			if _description:
				_description.text = data.description
		

@export var current_attack: int:
	set(value):
		current_attack = max(value, 0)
		if _attack_label:
			_attack_label.text = str(value)
			animate_pop(_attack_label.get_parent().get_parent() as Control)


@export var current_shield: int:
	set(value):
		if value <= 0:
			deactivate()
		elif current_shield <= 0 and value > 0:
			modulate.a = 1
		current_shield = value
		update_shield()


@export var overshield: int = 0:
	set(value):
		overshield = value
		update_shield()


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
	ability = _load_entity_behavior(entity_code)
	_nickname.text = data.nickname
	_description.text = data.description if data.description else "No special ability."
	_status_label.text = ""

	Utils.validate_vars(self , entity_code, data)


func _load_entity_behavior(code: String) -> EntityAbility:
	var path: String = CardDb.base_entity_ability_path % CardDb.get_entity_behavior_name(code)
	var script: GDScript = load(path)
	var entity_behavior := EntityAbility.new()
	entity_behavior.set_script(script)
	entity_behavior.user = self
	return entity_behavior


func activate() -> void:
	modulate.a = 1
	current_attack = max_attack
	current_shield = max_shield


func deactivate() -> void:
	modulate.a = 0.5


func animate_pop(node: Control) -> void:
	node.pivot_offset = node.size / 2
	var scale_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	scale_tween.tween_property(node, "scale", Vector2.ONE * 3, 0.1)
	scale_tween.tween_property(node, "scale", Vector2.ONE, 0.1)

	var rot_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	rot_tween.tween_property(node, "rotation", PI / 6.0, 0.1)
	rot_tween.tween_property(node, "rotation", -PI / 6.0, 0.1)
	rot_tween.tween_property(node, "rotation", 0, 0.1)


func update_shield() -> void:
	if _shield_label:
		var shown_shield: int = max(current_shield + overshield, 0)
		_shield_label.text = str(shown_shield)
		animate_pop(_shield_label.get_parent().get_parent() as Control)


func heal(amount: int) -> void:
	current_shield = min(max_shield, current_shield + amount)


func take_damage(amount: int) -> void:
	# have overshield take damage first until it is 0
	if overshield > 0:
		overshield -= amount
		# Bleed-over gets sent to shield
		if overshield < 0:
			current_shield -= abs(overshield)
			overshield = 0
	else:
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