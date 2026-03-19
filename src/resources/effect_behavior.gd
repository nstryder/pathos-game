extends Resource
class_name EffectBehavior


@warning_ignore("unused_parameter")
func enter(target_entity: EntityCard) -> void:
	pass


@warning_ignore("unused_parameter")
func exit(target_entity: EntityCard) -> void:
	pass


@warning_ignore("unused_parameter")
func use() -> void:
	pass


func modify_damage(incoming_damage: int) -> int:
	return incoming_damage
