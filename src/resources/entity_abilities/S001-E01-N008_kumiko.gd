extends EntityAbility


# Keep attached Effect cards until the next turn.
func activate(game_data: GameData) -> void:
    game_data.combat_data.entities[user].keep_fx_attach_longer = true