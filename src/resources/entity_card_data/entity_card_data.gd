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
var synergy_type
var name_of_set
var ability