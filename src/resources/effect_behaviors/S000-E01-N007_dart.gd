extends EffectBehavior


func enter(data: GameData) -> void:
    data.target_entity.status = EntityCard.Status.FATIGUED