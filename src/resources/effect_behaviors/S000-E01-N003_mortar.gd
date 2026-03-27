extends EffectBehavior


func enter(data: GameData) -> void:
	var enemy_player: Player
	if data.effect_player == data.server.player1:
		enemy_player = data.server.player2
	else:
		enemy_player = data.server.player1
	
	for entity in enemy_player.get_all_entities_in_play():
		if entity.is_revealed_permanently:
			entity.current_shield -= 1
