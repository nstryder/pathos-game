extends Node2D
class_name Deck

var player_deck: Array = ["A", "B", "C", "D", "E"]

@onready var player_hand: PlayerHand = %PlayerHand
@onready var card_manager: CardManager = %CardManager
@onready var card_counter: Label = %CardCounter


func _ready() -> void:
    card_counter.text = str(player_deck.size())


func draw_card() -> void:
    var card_drawn: String = player_deck.pop_front()
    card_counter.text = str(player_deck.size())
    if player_deck.is_empty():
        ($Area2D/CollisionShape2D as CollisionShape2D).disabled = true
        visible = false
    const card_scene = preload("uid://djf85mhy7rn64")
    var new_card: Card = card_scene.instantiate()
    card_manager.add_child(new_card)
    new_card.name = card_drawn
    new_card.global_position = global_position
    player_hand.add_card_to_hand(new_card)