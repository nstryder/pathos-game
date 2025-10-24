extends Node2D
class_name Player

signal hp_changed(new_hp: int)

const ENTITY_LIMIT = 3
const entity_card_scene = preload("uid://djf85mhy7rn64")
const effect_card_scene = preload("uid://lfqkryekm4io")

@export var id: int
@export var hp: int = 10:
	set(value):
		hp = value
		hp_changed.emit(value)
@export var base_entity_deck: Array[String] = []
@export var base_effect_deck: Array[String] = []

# All data below is stored as array of indexes referring to the base deck data above
# This makes it easier to serialize and sync over the network
# -1 index means a reserved slot that isn't actually filled yet

@export var entity_deck: Array[int] = []
@export var entities_in_play: Array[int] = [-1, -1, -1]
@export var attached_effects: Array[Array] = [[], [], []]
@export var entity_graveyard: Array[int] = []
@export var effect_deck: Array[int] = []
@export var effect_hand: Array[int] = []
@export var effect_discard_pile: Array[int] = []
@export var effect_exhaust_pile: Array[int] = []

# DO NOT MOVE OR FREE ANY CARD NODES CONTAINED IN THESE
@onready var entity_card_holder: Node2D = $EntityCards
@onready var effect_card_holder: Node2D = $EffectCards

@onready var syncer: MultiplayerSynchronizer = $MultiplayerSynchronizer


## This should only be called after both base entity and effect decks are set up
func initialize_decks() -> void:
	if not multiplayer.is_server():
		return

	for i in base_entity_deck.size():
		var entity_code: String = base_entity_deck[i]
		var entity_card: EntityCard = entity_card_scene.instantiate()
		entity_card.entity_code = entity_code
		entity_card.current_idx = i
		entity_card_holder.add_child(entity_card, true)
		
	for i in base_effect_deck.size():
		var effect_code: String = base_effect_deck[i]
		var effect_card: EffectCard = effect_card_scene.instantiate()
		effect_card.effect_code = effect_code
		effect_card.current_idx = i
		effect_card_holder.add_child(effect_card, true)
		
	entity_deck.assign(range(base_entity_deck.size()))
	entity_deck.shuffle()
	effect_deck.assign(range(base_effect_deck.size()))
	effect_deck.shuffle()


func draw_entities() -> void:
	if not multiplayer.is_server():
		return
	for i in ENTITY_LIMIT:
		var current_slot_idx: int = entities_in_play[i]
		if current_slot_idx == -1 and not entity_deck.is_empty():
			var drawn_entity_idx: int = entity_deck.pop_back()
			entities_in_play[i] = drawn_entity_idx


func draw_effects() -> void:
	if not multiplayer.is_server():
		return
	const DRAW_QUANTITY = 2
	for i in DRAW_QUANTITY:
		if effect_deck.is_empty():
			return
		effect_hand.append(effect_deck.pop_back())


func merge_effect_attachments(effect_attachments: Array[Array]) -> void:
	for slot_num: int in effect_attachments.size():
		var effect_indexes: Array = effect_attachments[slot_num]
		attached_effects[slot_num].append_array(effect_indexes)
		for effect_idx: int in effect_indexes:
			effect_hand.erase(effect_idx)


func get_entity_card_at_index(idx: int) -> EntityCard:
	return entity_card_holder.get_child(idx)


func get_effect_card_at_index(idx: int) -> EffectCard:
	return effect_card_holder.get_child(idx)


func get_entity_card_at_slot(slot_num: int) -> EntityCard:
	return get_entity_card_at_index(entities_in_play[slot_num])


func get_effect_cards_at_slot(slot_num: int) -> Array[EffectCard]:
	var effect_cards: Array[EffectCard] = []
	for effect_idx: int in attached_effects[slot_num]:
		effect_cards.append(get_effect_card_at_index(effect_idx))
	return effect_cards


func check_entity_deaths() -> void:
	for i in entities_in_play.size():
		var entity_idx: int = entities_in_play[i]
		if entity_idx == -1:
			continue
		var entity: EntityCard = get_entity_card_at_index(entity_idx)
		if entity.current_shield <= 0:
			entity_graveyard.append(entity_idx)
			entities_in_play[i] = -1
			var overdamage: int = abs(entity.current_shield)
			hp -= (2 + overdamage)
	draw_entities()
