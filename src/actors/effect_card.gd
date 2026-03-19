extends Card
class_name EffectCard


@export var effect_code: String
var data: EffectCardData
var behavior: EffectBehavior

@onready var nickname: Label = %Nickname
@onready var description: Label = %Description
@onready var effect_type: Label = %EffectType

func _ready() -> void:
	super._ready()
	
	data = CardDb.get_effect_by_code(effect_code)
	behavior = load_effect_behavior(effect_code)

	var affix := ""
	if data.usage_type == EffectCardData.UsageType.ATTACH:
		affix = "ATT"
	else:
		affix = "USE"
	nickname.text = data.effect_name + " (" + affix + ")"
	effect_type.text = EffectCardData.EffectType.keys()[data.effect_type]
	
	Utils.validate_vars(self , effect_code, data, behavior)

func load_effect_behavior(code: String) -> EffectBehavior:
	var path: String = CardDb.base_effect_behavior_path % CardDb.get_effect_behavior_name(code)
	var script: GDScript = load(path)
	var effect_behavior := EffectBehavior.new()
	effect_behavior.set_script(script)
	return effect_behavior
