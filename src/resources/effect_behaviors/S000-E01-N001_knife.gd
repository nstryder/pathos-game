extends EffectBehavior

const ATTACK_UP_AMOUNT = 2

func enter(data: GameData) -> void:
	data.target_entity.current_attack += ATTACK_UP_AMOUNT


func exit(data: GameData) -> void:
	data.target_entity.current_attack -= ATTACK_UP_AMOUNT
