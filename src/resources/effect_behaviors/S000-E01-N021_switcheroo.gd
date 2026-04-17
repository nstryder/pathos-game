extends EffectBehavior


func enter(data: GameData) -> void:
	var current_shield: int = data.target_entity.current_shield
	data.target_entity.current_shield = data.target_entity.current_attack
	data.target_entity.current_attack = current_shield


func exit(data: GameData) -> void:
	# Swapping twice reverts it, so we can just call the swap again
	enter(data)
