extends Card
class_name EffectCard


@export var effect_code: String
var effect_card_data: EffectCardData

@onready var nickname: Label = %Nickname
@onready var description: Label = %Description
@onready var effect_type: Label = %EffectType

var assigned_entity: EntityCard:
	get:
		for slot_idx: int in player.attached_effects.size():
			var slot: Array = player.attached_effects[slot_idx]
			if current_idx in slot:
				return player.get_entity_card_at_slot(slot_idx)
		return null


func _ready() -> void:
	super._ready()
	effect_card_data = CardDb.get_effect_by_code(effect_code)
	nickname.text = effect_card_data.effect_name
	effect_type.text = EffectCardData.EffectType.keys()[effect_card_data.effect_type]
	
	Utils.validate_vars(self, effect_code, effect_card_data)
