extends Resource
class_name EntityCardData

enum Rarity {
    CHARACTER,
    PROTAGONIST
}

@export var nickname: String
@export var base_attack: int
@export var base_shield: int
@export var rarity: Rarity = Rarity.CHARACTER
@export var description: String
@export var amp_description: String
var synergy_type: Variant
var name_of_set: Variant
