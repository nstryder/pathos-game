extends Node2D
class_name Deck

# Consider breaking this up into two inherited classes
# Since this has two responsibilities (effect and entities)

const entity_card_scene = preload("uid://djf85mhy7rn64")
const effect_card_scene = preload("uid://lfqkryekm4io")

enum DeckType {
	ENTITY,
	EFFECTS
}

@export var deck_type: DeckType = DeckType.ENTITY

## These MUST be set upon instantiating this scene
var deck: Array
var card_scene: PackedScene
var deck_player: Player
var entity_slot_markers: EntitySlotMarkers
var player_hand: PlayerHand

# @onready var card_manager: CardManager = %CardManager
@onready var card_counter: Label = %CardCounter


func _ready() -> void:
	if deck_type == DeckType.ENTITY:
		card_scene = entity_card_scene
	else:
		card_scene = effect_card_scene


func set_entity_marker_node(marker_node: EntitySlotMarkers) -> void:
	entity_slot_markers = marker_node


func update_counter() -> void:
	card_counter.text = str(deck.size())
	if deck.is_empty():
		visible = false


func set_deck(new_deck: Array) -> void:
	deck = new_deck
	update_counter()


func realize_entity_state(is_enemy: bool = false) -> void:
	if entity_slot_markers.current_idx_representation == deck_player.entities_in_play:
		return
	hide_old_entities_in_play()
	for slot_num: int in deck_player.entities_in_play.size():
		var entity_idx: int = deck_player.entities_in_play[slot_num]
		if entity_idx == -1: continue
		var entity_card: EntityCard = deck_player.get_entity_card_at_index(entity_idx)
		var new_pos: Vector2 = entity_slot_markers.get_position_at_slot(slot_num)
		entity_card.global_position = new_pos
		entity_card.slot_attachment_effects_enable()
		entity_card.current_slot = slot_num
		entity_card.is_enemy = is_enemy
	update_counter()


func realize_effect_state() -> void:
	for effect_idx: int in deck_player.effect_hand:
		var effect_card: EffectCard = deck_player.get_effect_card_at_index(effect_idx)
		effect_card.global_position = global_position
		player_hand.add_card_to_hand(effect_card)
	update_counter()


func hide_old_entities_in_play() -> void:
	for entity_idx: int in entity_slot_markers.current_idx_representation:
		if entity_idx == -1: continue
		var current_card: EntityCard = deck_player.get_entity_card_at_index(entity_idx)
		current_card.hide_from_field()
