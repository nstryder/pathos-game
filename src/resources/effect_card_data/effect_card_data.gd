extends Resource
class_name EffectCardData

enum EffectType {
    OFFENSIVE,
    DEFENSIVE,
    SPECIAL
}

enum Identifier {
    ITEM,
    SKILL,
    STATUS
}

enum AbilityPhase {
    BOTH,
    OFFENSE,
    DEFENSE,
    NONE
}

enum TimelineCondition {
    NONE,
    IMMEDIATE
}

enum UsageType {
    USE,
    ATTACH
}

@export var effect_name: String
@export var effect_type: EffectType = EffectType.OFFENSIVE
@export var identifier: Identifier = Identifier.ITEM
@export var ability_phase: AbilityPhase = AbilityPhase.BOTH
@export var usage_type: UsageType = UsageType.USE
@export var timeline_condition: TimelineCondition = TimelineCondition.NONE