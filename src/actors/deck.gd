extends Node2D
class_name Deck

const entity_card_scene = preload("uid://djf85mhy7rn64")
const effect_card_scene = preload("uid://lfqkryekm4io")

enum DeckType {
    ENTITY,
    EFFECTS
}

@export var deck_type: DeckType = DeckType.ENTITY

var deck: Array
var card_scene: PackedScene
var deck_player: Player

# @onready var player_hand: PlayerHand = %PlayerHand
# @onready var card_manager: CardManager = %CardManager
@onready var card_counter: Label = %CardCounter


func _ready() -> void:
    if deck_type == DeckType.ENTITY:
        card_scene = entity_card_scene
    else:
        card_scene = effect_card_scene


func update_counter() -> void:
    card_counter.text = str(deck.size())


func set_deck(new_deck: Array) -> void:
    deck = new_deck
    update_counter()


func draw_card() -> void:
    update_counter()
    if deck.is_empty():
        visible = false
    var new_card: Card = card_scene.instantiate()
    # card_manager.add_child(new_card)
    # new_card.name = card_drawn
    new_card.global_position = global_position
    # player_hand.add_card_to_hand(new_card)


func sync_entities() -> void:
    pass