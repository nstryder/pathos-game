extends Node2D
class_name PlayerHand
"""
Code gathered from Barry's Dev Hell.
Critiques:
    - PlayerHand and CardManager reference each other
    - They both also could fight over card position
    - Positions are hard set via constants. 
        - It would be better to have this behave more similar to a Control
        - I.e. placing this node's actual position in bottom center
        - and using that position (maybe use a Control child later?)
"""

const HAND_COUNT = 5
const CARD_WIDTH = 250
const HAND_Y_POSITION = 890
@export var card_manager: Node2D

var player_hand: Array[Card] = []

func _ready() -> void:
    const card_scene = preload("uid://djf85mhy7rn64")
    for i in range(HAND_COUNT):
        var new_card: Card = card_scene.instantiate()
        card_manager.add_child(new_card)
        new_card.name = "card"
        add_card_to_hand(new_card)


func add_card_to_hand(card: Card) -> void:
    player_hand.insert(0, card)
    update_hand_positions()


func update_hand_positions() -> void:
    for i in range(player_hand.size()):
        var new_position := Vector2(calculate_card_position(i), HAND_Y_POSITION)
        var card := player_hand[i]
        card.starting_position = new_position
        animate_card_to_position(card, new_position)


func calculate_card_position(index: int) -> float:
    var total_width: float = (player_hand.size() - 1) * CARD_WIDTH
    var centering_offset := total_width / 2
    var x_offset := get_screen_center_x() + index * CARD_WIDTH - centering_offset
    return x_offset


func animate_card_to_position(card: Card, new_position: Vector2) -> void:
    var tween := create_tween()
    tween.tween_property(card, "position", new_position, 0.1) \
        .set_trans(Tween.TRANS_SPRING) \
        .set_ease(Tween.EASE_OUT)


func remove_card_from_hand(card: Card) -> void:
    if card in player_hand:
        player_hand.erase(card)
        update_hand_positions()


func get_screen_center_x() -> float:
    return get_viewport_rect().size.x / 2