extends Screen


signal start_game


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_back_button_pressed() -> void:
	get_parent().transition(ScreenManager.Screens.START)


func _create_lobby_data() -> Dictionary:
	var lobby_data: Dictionary = {
		"Map": preload("res://Maps/Map.tscn").instance()
	}
	return lobby_data


func _on_play_button_pressed() -> void:
	get_parent().transition(ScreenManager.Screens.GAME)
	emit_signal("start_game", _create_lobby_data())
