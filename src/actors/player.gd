extends Node
class_name Player


@export var id: int
@export var base_entity_deck: Array[String] = []
@export var base_effect_deck: Array[String] = []

# All data below is saved as array of indexes referring to the base deck data above
# This makes it easier to serialize and sync over the network

@export var entity_deck: Array[int] = []
@export var entities_in_play: Array[int] = []
@export var entity_graveyard: Array[int] = []
@export var effect_deck: Array[int] = []
@export var effect_hand: Array[int] = []
@export var effect_discard_pile: Array[int] = []
@export var effect_exhaust_pile: Array[int] = []

# This should only be called after both base decks are set up
func initialize_decks() -> void:
	entity_deck.assign(range(base_entity_deck.size()))
	entity_deck.shuffle()
	effect_deck.assign(range(base_effect_deck.size()))
	effect_deck.shuffle()
