extends Condition


func on_pre_damage_given(attacker: EntityCard, defender: EntityCard) -> void:
	attacker.current_attack = defender.current_attack
