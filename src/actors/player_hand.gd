extends Node2D
class_name PlayerHand


const CARD_WIDTH = 250
const ANIMATION_TWEEN_TIME = 0.2

var player_hand: Array[int]:
	get:
		return player_side.player.effect_hand


@onready var player_side: PlayerSide = owner


# TODO
func update_hand_positions() -> void:
	for i in player_hand.size():
		var effect_idx := player_hand[i]
		var new_position := Vector2(calculate_card_position(i), global_position.y)
		var card := player_side.player.get_effect_card_at_index(effect_idx)
		card.detectable = true
		card.slot_attachment_effects_disable()
		card.starting_position = new_position
		animate_card_to_position(card, new_position)


func calculate_card_position(index: int) -> float:
	var total_width: float = (player_hand.size() - 1) * CARD_WIDTH
	var centering_offset := total_width / 2
	var x_offset := get_screen_center_x() + index * CARD_WIDTH - centering_offset
	return x_offset


func animate_card_to_position(card: Card, new_position: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(card, "global_position", new_position, ANIMATION_TWEEN_TIME) \
		.set_trans(Tween.TRANS_SPRING) \
		.set_ease(Tween.EASE_OUT)


func get_screen_center_x() -> float:
	return get_viewport_rect().size.x / 2
