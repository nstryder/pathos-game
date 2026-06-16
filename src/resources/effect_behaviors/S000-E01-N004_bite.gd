extends EffectBehavior


func enter(data: GameData) -> void:
	data.target_entity.add_condition("uid://5wlge7x6o2s")
	data.target_entity.current_attack += 1


func exit(data: GameData) -> void:
	data.target_entity.current_attack -= 1