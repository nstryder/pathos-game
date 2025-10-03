extends Node2D
class_name Player

const ENTITY_LIMIT = 3
const entity_card_scene = preload("uid://djf85mhy7rn64")
const effect_card_scene = preload("uid://lfqkryekm4io")

signal entity_drawn(slot_num: int, entity_card: EntityCard)

@export var id: int
@export var base_entity_deck: Array[String] = []
@export var base_effect_deck: Array[String] = []

# All data below is stored as array of indexes referring to the base deck data above
# This makes it easier to serialize and sync over the network
# -1 index means a reserved slot that isn't actually filled yet

@export var entity_deck: Array[int] = []
@export var entities_in_play: Array[int] = [-1, -1, -1]
@export var entity_graveyard: Array[int] = []
@export var effect_deck: Array[int] = []
@export var effect_hand: Array[int] = []
@export var effect_discard_pile: Array[int] = []
@export var effect_exhaust_pile: Array[int] = []

var entity_cards: Array[EntityCard]
var effect_cards: Array[EffectCard]

@onready var entity_card_holder: Node2D = $EntityCards
@onready var effect_card_holder: Node2D = $EffectCards


## This should only be called after both base entity and effect decks are set up.
func initialize_decks() -> void:
	if not multiplayer.is_server():
		return

	for entity_code in base_entity_deck:
		var entity_card: EntityCard = entity_card_scene.instantiate()
		entity_card.entity_code = entity_code
		entity_card_holder.add_child(entity_card, true)
		entity_cards.append(entity_card)
		entity_card.hide_from_field.rpc()
	for effect_code in base_effect_deck:
		var effect_card: EffectCard = effect_card_scene.instantiate()
		effect_card.effect_code = effect_code
		effect_card_holder.add_child(effect_card, true)
		effect_cards.append(effect_card)
		effect_card.hide_from_field.rpc()

	entity_deck.assign(range(base_entity_deck.size()))
	entity_deck.shuffle()
	effect_deck.assign(range(base_effect_deck.size()))
	effect_deck.shuffle()


func draw_entities() -> void:
	for i in range(ENTITY_LIMIT):
		var current_slot_idx: int = entities_in_play[i]
		if current_slot_idx == -1 and not entity_deck.is_empty():
			var drawn_entity_idx: int = entity_deck.pop_back()
			entities_in_play[i] = drawn_entity_idx
			var entity_card: EntityCard = entity_cards[drawn_entity_idx]
			entity_drawn.emit(i, entity_card)
