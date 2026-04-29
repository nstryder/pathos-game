extends EffectBehavior


func enter(data: GameData) -> void:
	var enemy_player: Player = data.get_opponent()
	
	for entity in enemy_player.get_all_entities_in_play():
		if entity.is_revealed:
			data.server.combat_manager.deal_global_damage(entity, 1)
