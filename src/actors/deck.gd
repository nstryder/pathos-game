extends Node2D
class_name Deck

@onready var card_counter: Label = %CardCounter

func update_counter(deck: Array) -> void:
	card_counter.text = str(deck.size())
	if deck.is_empty():
		visible = false
