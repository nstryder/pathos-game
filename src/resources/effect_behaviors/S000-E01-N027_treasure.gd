extends EffectBehavior


func enter(data: GameData) -> void:
    data.effect_player.draw_effects(1)
    data.server.sync_client_hands()