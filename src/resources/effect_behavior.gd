extends Resource
class_name EffectBehavior


## Data class to pass into this behavior's methods.
## We use this to make it easier to add new parameters
## Instead of changing the function parameters every time
class GameData:
	var effect_player: Player
	var target_entity: EntityCard
	var server: ServerState

	func get_opponent() -> Player:
		if effect_player == server.player1:
			return server.player2
		else:
			return server.player1


var effect_data: EffectCardData


@warning_ignore("unused_parameter")
func enter(data: GameData) -> void:
	pass


@warning_ignore("unused_parameter")
func exit(data: GameData) -> void:
	pass
