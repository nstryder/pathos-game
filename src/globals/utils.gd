extends Node


func sleep(time_sec: float) -> void:
    await get_tree().create_timer(time_sec).timeout