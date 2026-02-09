extends EffectBehavior

const ATTACK_UP_AMOUNT = 2

func on_entry(effect_card: EffectCard) -> void:
	effect_card.assigned_entity.current_attack += ATTACK_UP_AMOUNT


func on_discard(effect_card: EffectCard) -> void:
	effect_card.assigned_entity.current_attack -= ATTACK_UP_AMOUNT
