extends Card
class_name EffectCard


@export var effect_code: String
var data: EffectCardData

@onready var nickname: Label = %Nickname
@onready var description: Label = %Description
@onready var effect_type: Label = %EffectType

func _ready() -> void:
	super._ready()
	
	data = CardDb.get_effect_by_code(effect_code)
	var affix := ""
	if data.usage_type == EffectCardData.UsageType.ATTACH:
		affix = "ATT"
	else:
		affix = "USE"
	nickname.text = data.effect_name + " (" + affix + ")"
	effect_type.text = EffectCardData.EffectType.keys()[data.effect_type]
	
	Utils.validate_vars(self , effect_code, data)
