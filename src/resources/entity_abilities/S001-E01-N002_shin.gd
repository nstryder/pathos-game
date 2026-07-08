extends EntityAbility

# Deal 3 DMG back at the enemy Entity after being hit in combat.
func activate(_game_data: GameData) -> void:
    user.add_condition("res://src/resources/entity_conditions/counterattack.tscn")