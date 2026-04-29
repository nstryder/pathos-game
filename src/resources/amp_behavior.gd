extends EffectBehavior
class_name AmpBehavior


func enter(data: GameData) -> void:
    print("Target: ", data.target_entity.data.nickname)
    print("Trying to amp: ", effect_data.amp_protagonist)
    if data.target_entity.data.nickname == effect_data.amp_protagonist:
        data.target_entity.is_amped = true
        print("Amping ", data.target_entity.data.nickname)


func exit(data: GameData) -> void:
    if data.target_entity.data.nickname == effect_data.amp_protagonist:
        data.target_entity.is_amped = false