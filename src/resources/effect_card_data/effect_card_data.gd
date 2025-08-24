extends Resource
class_name EffectCardData

enum EffectType {
    OFFENSE,
    DEFENSE,
    SPECIAL
}

enum Identifier {
    ITEM,
    SKILL,
    STATUS
}

enum AbilityPhase {
    BOTH,
    ATTACK,
    DEFENSE,
    NONE
}

enum TimelineCondition {
    NONE,
    IMMEDIATE
}

enum UsageType {
    CONSUME,
    ATTACH
}

@export var effect_name: String
@export var effect_type: EffectType = EffectType.OFFENSE
@export var identifier: Identifier = Identifier.ITEM
@export var ability_phase: AbilityPhase = AbilityPhase.BOTH
@export var usage_type: UsageType = UsageType.CONSUME
@export var timeline_condition: TimelineCondition = TimelineCondition.NONE