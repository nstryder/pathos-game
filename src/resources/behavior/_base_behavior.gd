extends Resource
class_name Behavior

enum ConditionEnum {
    DEFAULT,
    IMMEDIATE,
    PASSIVE,
    ON_DAMAGE_RECEIVED,
    ON_DAMAGE_GIVEN
}

@export var description: String
@export var activation_condition: ConditionEnum

func activate() -> void:
    pass