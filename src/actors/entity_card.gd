extends Card
class_name EntityCard

@export var entity_code: String
var entity_card_data: EntityCardData

var max_attack: int
var max_shield: int
@export var current_attack: int:
	set(value):
		current_attack = value
		if attack_label:
			attack_label.text = str(value)
@export var current_shield: int:
	set(value):
		current_shield = value
		if shield_label:
			shield_label.text = str(value)

@onready var nickname: Label = %Nickname
@onready var description: Label = %Description
@onready var attack_label: Label = %Attack
@onready var shield_label: Label = %Shield


func _ready() -> void:
	entity_card_data = CardDb.get_entity_by_code(entity_code)

	max_attack = entity_card_data.base_attack
	max_shield = entity_card_data.base_shield
	current_attack = max_attack
	current_shield = max_shield

	nickname.text = entity_card_data.nickname
