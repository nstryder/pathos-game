extends PanelContainer


func _on_card_manager_use_fx_dragged() -> void:
	show()


func _on_card_manager_use_fx_released() -> void:
	hide()
