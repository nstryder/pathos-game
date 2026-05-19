extends EntityAbility


# Draw 1 Effect card.
func activate(data: GameData) -> void:
    user.player.draw_effects(1)
    data.server.sync_client_hands()