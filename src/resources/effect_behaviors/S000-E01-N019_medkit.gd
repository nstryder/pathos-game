extends EffectBehavior

const HEAL_AMOUNT = 3

func enter(data: GameData) -> void:
	data.target_entity.current_shield = min(data.target_entity.max_shield, data.target_entity.current_shield + HEAL_AMOUNT)
