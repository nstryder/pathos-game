extends Resource
class_name EntityAbility


class GameData:
    var server: ServerState
    var combat_data: CombatManager.CombatData


var user: EntityCard


@warning_ignore("unused_parameter")
func activate(game_data: GameData) -> void:
    pass