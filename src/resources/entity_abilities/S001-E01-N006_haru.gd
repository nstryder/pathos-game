extends EntityAbility


# Shuffle your Effect discard pile back into your Effect draw pile
func activate(game_data: GameData) -> void:
    user.player.return_discards_to_deck()
    game_data.server.sync_client_hands()
