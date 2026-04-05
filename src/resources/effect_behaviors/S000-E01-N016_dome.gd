extends EffectBehavior


func enter(data: GameData) -> void:
    data.combat_data.players[data.effect_player].overdamage_modifier = 0