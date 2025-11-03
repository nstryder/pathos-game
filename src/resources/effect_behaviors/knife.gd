extends EffectBehavior


func on_entry(effect_card: EffectCard) -> void:
    effect_card.assigned_entity.current_attack += 2


func on_discard(effect_card: EffectCard) -> void:
    effect_card.assigned_entity.current_attack -= 2