extends EntityAbility


# Keep attached Effect cards until the next turn.
func activate(_game_data: GameData) -> void:
    user.keep_fx_attach_longer = true