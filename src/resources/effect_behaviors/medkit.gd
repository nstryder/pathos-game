extends EffectBehavior

const HEAL_AMOUNT = 3

func on_entry(effect_card: EffectCard) -> void:
	var entity := effect_card.assigned_entity
	entity.current_shield = min(entity.max_shield, entity.current_shield + HEAL_AMOUNT)
	


#func on_discard(effect_card: EffectCard) -> void:
	#pass
