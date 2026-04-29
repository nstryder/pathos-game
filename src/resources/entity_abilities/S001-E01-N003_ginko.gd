extends EntityAbility

# Deal her ATK to all Revealed Entities other than herself.
func activate(game_data: GameData) -> void:
    var combat_manager: CombatManager = game_data.server.combat_manager
    var reveals: Array[EntityCard] = combat_manager.get_all_revealed_entities()
    for entity in reveals:
        if entity == user:
            continue
        combat_manager.deal_damage(user, entity, user.current_attack)


# Deal her ATK to all Entities other than herself.
func activate_amped(game_data: GameData) -> void:
    print("Activating Amped effect!!!")
    var combat_manager: CombatManager = game_data.server.combat_manager
    var entities: Array[EntityCard] = combat_manager.get_all_active_entities()
    for entity in entities:
        if entity == user:
            continue
        combat_manager.deal_damage(user, entity, user.current_attack)
