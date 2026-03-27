extends Condition


func on_post_damage_given(attacker: EntityCard, _defender: EntityCard) -> void:
	attacker.heal(1)