extends Resource
class_name EffectBehavior


class GameData:
	var effect_player: Player
	var target_entity: EntityCard
	var server: ServerState

	func get_opponent() -> Player:
		if effect_player == server.player1:
			return server.player2
		else:
			return server.player1


@warning_ignore("unused_parameter")
func enter(data: GameData) -> void:
	pass


@warning_ignore("unused_parameter")
func exit(data: GameData) -> void:
	pass


@warning_ignore("unused_parameter")
func use() -> void:
	pass


func modify_damage(incoming_damage: int) -> int:
	return incoming_damage
