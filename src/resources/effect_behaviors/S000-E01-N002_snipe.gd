extends EffectBehavior


func enter(data: GameData) -> void:
    # Snipe should only affect the ATTACKER
    # if you attach this on a card that isn't attacking...it should do virtually nothing
    var combat_manager: CombatManager = data.server.combat_manager
    if combat_manager.attack_is_declared() and data.target_entity == combat_manager.get_current_attacker():
        data.combat_data.damage_receiver = combat_manager.defending_player.take_damage