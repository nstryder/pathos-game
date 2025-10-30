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


#region ENTITY METHODS

func realize_entity_state() -> void:
	await hide_dead_entities()
	var tween: Tween = null
	for slot_num: int in player.entities_in_play.size():
		var entity_idx: int = player.entities_in_play[slot_num]
		if entity_idx == -1: continue
		var entity_card: EntityCard = player.get_entity_card_at_index(entity_idx)
		var new_pos: Vector2 = entity_slot_markers.get_position_at_slot(slot_num)
		var entity_is_already_in_play := new_pos == entity_card.global_position
		if entity_is_already_in_play:
			continue
		entity_card.activate()
		entity_card.slot_attachment_effects_enable()
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

#endregion 
#region EFFECT METHODS

func realize_effect_state() -> void:
	for effect_idx: int in player.effect_hand:
		var effect_card: EffectCard = player.get_effect_card_at_index(effect_idx)
		effect_card.global_position = global_position
		effect_card.is_veiled = is_enemy
		hand.update_hand_positions()
	effect_deck.update_counter(player.effect_deck)


func arrange_attached_effects(attachments: Array[Array]) -> void:
	const CARD_SPACING = 32
	for slot_num in attachments.size():
		var slot_attachments: Array = attachments[slot_num]
		for i in slot_attachments.size():
			var effect_idx: int = slot_attachments[i]
			var effect_card := player.get_effect_card_at_index(effect_idx)
			effect_card.slot_attachment_effects_enable()
			effect_card.z_index = Constants.MIN_ATTACHMENT_Z_INDEX - (i + 1)
			effect_card.detectable = false

			var target_entity := player.get_entity_card_at_slot(slot_num)
			var offset := Vector2(0, CARD_SPACING * (i + 1))
			var new_pos := target_entity.global_position - offset
			effect_card.global_position = new_pos

#endregion