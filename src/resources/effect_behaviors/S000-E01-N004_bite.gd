extends EffectBehavior

# TODO: Attach Bite condition to entity


func enter(data: GameData) -> void:
	data.target_entity.add_condition("uid://5wlge7x6o2s")
	data.target_entity.current_attack += 1
