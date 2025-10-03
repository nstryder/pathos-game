extends Card
class_name EffectCard


@export var effect_code: String
var effect_card_data: EffectCardData

@onready var nickname: Label = %Nickname
@onready var description: Label = %Description
@onready var effect_type: Label = %EffectType

func _ready() -> void:
    effect_card_data = CardDb.get_effect_by_code(effect_code)
    nickname.text = effect_card_data.effect_name
    effect_type.text = EffectCardData.EffectType.keys()[effect_card_data.effect_type]
