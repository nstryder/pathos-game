extends EffectBehavior


func on_entry(effect_card: EffectCard) -> void:
	var entity: EntityCard = effect_card.assigned_entity
	var current_shield: int = entity.current_shield
	entity.current_shield = entity.current_attack
	entity.current_attack = current_shield


func on_discard(effect_card: EffectCard) -> void:
	# Swapping twice reverts it, so we can just call the swap again
	on_entry(effect_card)
