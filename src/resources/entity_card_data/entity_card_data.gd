extends Resource
class_name EntityCardData

enum Rarity {
    CHARACTER,
    PROTAGONIST
}
enum EntityTimelineCondition {
    NONE,
    IMMEDIATE
}

@export var nickname: String
@export var base_attack: int
@export var base_shield: int
@export var rarity: Rarity = Rarity.CHARACTER
@export var timeline_condition: EntityTimelineCondition = EntityTimelineCondition.NONE
@export var description: String
@export var amp_description: String
@export var synergy_name: String
