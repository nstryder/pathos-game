extends EffectBehavior

const HEAL_AMOUNT = 3

func enter(data: GameData) -> void:
	data.target_entity.heal(HEAL_AMOUNT)
