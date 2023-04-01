extends Screen


func _on_quit_button_pressed() -> void:
	$Popup.popup_centered()


func _on_confirm_quit_button_pressed() -> void:
	get_tree().quit()


func _on_cancel_quit_button_pressed() -> void:
	$Popup.hide()


func connect_signals(node: Node) -> void:
	$"%PlayButton".connect("pressed", node, "_on_play_button_pressed")
	$"%SettingsButton".connect("pressed", node, "_on_settings_button_pressed")
