extends Node2D
class_name Condition

@export var hijacks_damage_calculation: bool = false


@warning_ignore("unused_parameter")
func on_post_damage_given(attacker: EntityCard, defender: EntityCard) -> void:
	pass