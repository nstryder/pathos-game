extends Card
class_name EffectCard


@export var effect_code: String
var effect_card_data: EffectCardData

@onready var nickname: Label = %Nickname
@onready var description: Label = %Description
@onready var effect_type: Label = %EffectType

func _ready() -> void:
	super._ready()
	
	effect_card_data = CardDb.get_effect_by_code(effect_code)
	var affix := ""
	if effect_card_data.effect_type == EffectCardData.UsageType.ATTACH:
		affix = "ATT"
	else:
		affix = "USE"
	nickname.text = effect_card_data.effect_name + " (" + affix + ")"
	effect_type.text = EffectCardData.EffectType.keys()[effect_card_data.effect_type]
	
	Utils.validate_vars(self , effect_code, effect_card_data)
