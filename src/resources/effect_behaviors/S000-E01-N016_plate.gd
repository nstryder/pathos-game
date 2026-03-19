extends EffectBehavior

const SHIELD_UP_AMOUNT = 2

func enter(target_entity: EntityCard) -> void:
	target_entity.current_shield += SHIELD_UP_AMOUNT


func exit(target_entity: EntityCard) -> void:
	target_entity.current_shield -= SHIELD_UP_AMOUNT
