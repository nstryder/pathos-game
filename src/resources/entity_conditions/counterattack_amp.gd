extends Condition


# Deal 5 DMG back at the enemy Entity after being hit in combat.
func on_post_damage_taken(attacker: EntityCard, _defender: EntityCard) -> void:
	combat_manager.deal_global_damage(attacker, 5)
