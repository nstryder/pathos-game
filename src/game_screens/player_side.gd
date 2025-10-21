@tool
extends Node2D
class_name PlayerSide

@export var is_enemy: bool = false

## Player MUST be set during game setup
var player: Player
@onready var effect_deck: Deck = %EffectDeck
@onready var entity_deck: Deck = %EntityDeck
@onready var hand: PlayerHand = %Hand
@onready var entity_slot_markers: EntitySlotMarkers = %EntitySlotMarkers


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for node: Node2D in [effect_deck, entity_deck, hand, entity_slot_markers]:
		# Undo rotation
		node.global_rotation -= node.global_rotation


func realize_entity_state() -> void:
	await hide_dead_entities()
	var tween: Tween = null
	for slot_num: int in player.entities_in_play.size():
		var entity_idx: int = player.entities_in_play[slot_num]
		if entity_idx == -1: continue
		var entity_card: EntityCard = player.get_entity_card_at_index(entity_idx)
		var entity_is_already_in_play := entity_card.current_slot != -1
		if entity_is_already_in_play:
			continue
		var new_pos: Vector2 = entity_slot_markers.get_position_at_slot(slot_num)
		entity_card.activate()
		entity_card.slot_attachment_effects_enable()
		entity_card.current_slot = slot_num
		entity_card.is_enemy = is_enemy
		entity_card.is_veiled = is_enemy

		if not tween:
			tween = create_tween()
		entity_card.global_position = global_position
		tween.tween_property(entity_card, "global_position", new_pos, 0.1)
	entity_deck.update_counter(player.entity_deck)


func hide_dead_entities() -> void:
	if player.entity_graveyard.is_empty():
		return
	var tween := create_tween()
	for entity_idx: int in player.entity_graveyard:
		var current_card: EntityCard = player.get_entity_card_at_index(entity_idx)
		current_card.current_idx = -1
		tween.tween_property(current_card, "global_position", Vector2.ZERO, 0.1)
		tween.tween_callback(current_card.hide_from_field)
	await tween.finished


func realize_effect_state() -> void:
	for effect_idx: int in player.effect_hand:
		var effect_card: EffectCard = player.get_effect_card_at_index(effect_idx)
		effect_card.global_position = global_position
		effect_card.is_veiled = is_enemy
		hand.add_card_to_hand(effect_card)
	effect_deck.update_counter(player.effect_deck)
