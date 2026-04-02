extends EffectBehavior


func enter(data: GameData) -> void:
    data.effect_player.draw_effects(1)
    await data.server.get_tree().process_frame
    data.server.client.sync_hands.rpc()