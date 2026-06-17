extends EntityAbility

# Negate the enemy Entity's ability in combat.
func activate(game_data: GameData) -> void:
    var enemy: EntityCard = game_data.server.combat_manager.get_opposing_entity_to(user)
    if enemy:
        game_data.combat_data.entities[enemy].can_use_ability = false
