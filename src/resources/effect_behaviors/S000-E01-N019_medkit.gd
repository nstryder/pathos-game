extends EffectBehavior

const HEAL_AMOUNT = 3

func enter(target_entity: EntityCard) -> void:
	target_entity.current_shield = min(target_entity.max_shield, target_entity.current_shield + HEAL_AMOUNT)
	

#func on_discard(effect_card: EffectCard) -> void:
	#pass
