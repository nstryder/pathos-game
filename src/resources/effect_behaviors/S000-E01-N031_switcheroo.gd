extends EffectBehavior


func enter(target_entity: EntityCard) -> void:
	var current_shield: int = target_entity.current_shield
	target_entity.current_shield = target_entity.current_attack
	target_entity.current_attack = current_shield


func exit(target_entity: EntityCard) -> void:
	# Swapping twice reverts it, so we can just call the swap again
	enter(target_entity)
