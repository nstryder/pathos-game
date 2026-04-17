extends EffectBehavior

func enter(data: GameData) -> void:
    var opponent: Player = data.get_opponent()
    for effect_idx: int in opponent.effect_hand.duplicate():
        opponent.return_effect_to_deck(effect_idx)

    opponent.effect_deck.shuffle()
    opponent.draw_effects(2)

    data.server.sync_client_hands()