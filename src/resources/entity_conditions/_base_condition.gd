extends Node2D
class_name Condition


@onready var combat_manager: CombatManager = get_tree().get_nodes_in_group("CombatManager")[0]


@warning_ignore("unused_parameter")
func on_pre_damage_given(attacker: EntityCard, defender: EntityCard) -> void:
	pass


@warning_ignore("unused_parameter")
func on_post_damage_given(attacker: EntityCard, defender: EntityCard) -> void:
	pass


@warning_ignore("unused_parameter")
func on_post_damage_taken(attacker: EntityCard, defender: EntityCard) -> void:
	pass