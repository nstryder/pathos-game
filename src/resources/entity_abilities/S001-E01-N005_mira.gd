extends EntityAbility

# Permanently Copy the ATK of the first Entity you attack.
func activate(_game_data: GameData) -> void:
    user.add_condition("uid://c0n3pek3aobko")