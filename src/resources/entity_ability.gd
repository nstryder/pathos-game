extends Resource
class_name EntityAbility


## Data class to pass into the ability methods.
## We use this to make it easier to add new parameters
## Instead of changing the function parameters every time
class GameData:
    var server: ServerState


var user: EntityCard


@warning_ignore("unused_parameter")
func activate(game_data: GameData) -> void:
    pass


@warning_ignore("unused_parameter")
func activate_amped(game_data: GameData) -> void:
    pass