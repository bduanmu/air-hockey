extends Screen


func _on_settings_button_pressed() -> void:
	get_parent().transition(ScreenManager.Screens.SETTINGS)


func _on_play_button_pressed() -> void:
	get_parent().transition(ScreenManager.Screens.LOBBY)


func _on_quit_button_pressed() -> void:
	$Popup.popup_centered()


func _on_confirm_quit_button_pressed() -> void:
	get_tree().quit()


func _on_cancel_quit_button_pressed() -> void:
	$Popup.hide()
