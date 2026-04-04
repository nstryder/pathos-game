extends EffectBehavior


func enter(data: GameData) -> void:
    # Snipe should only affect the ATTACKER
    # if you attach this on a card that isn't attacking...it should do virtually nothing
    data.combat_data.entities[data.target_entity].hit_player_instead = true