class_name SettingsScreen extends Screen


enum ScreenMode {
	FULLSCREEN, WINDOWED, BORDERLESS
}


var config := ConfigFile.new()


func _ready() -> void:
	load_settings()


func _on_screen_type_changed(state: int) -> void:
	if state == ScreenMode.FULLSCREEN:
		OS.window_borderless = false
		OS.window_fullscreen = true
	elif state == ScreenMode.WINDOWED:
		OS.window_fullscreen = false
		OS.window_borderless = false
	else:
		OS.window_fullscreen = false
		OS.window_borderless = true
		OS.window_size = Vector2(1920, 1080)


func save() -> void:
	config.set_value("Video", "Window Mode", $"%ScreenType".current_state)
	config.set_value("Audio", "Master Volume", $"%MasterVolumeSlider".value)
	config.save("settings.cfg")


func load_settings() -> void:
	# Load data from a file.
	var err = config.load("settings.cfg")
	
	# If the file didn't load, ignore it.
	if err != OK:
		return
	
	# Fetch the data for each section.
	if config.get_value("Video", "Window Mode") != null:
		$"%ScreenType".current_state = config.get_value("Video", "Window Mode")
	if config.get_value("Audio", "Master Volume") != null:
		$"%MasterVolumeSlider".value = config.get_value("Audio", "Master Volume")


func _on_back_button_pressed() -> void:
	save()
	get_parent().transition(ScreenManager.Screens.START)


func _on_master_volume_changed(volume: int) -> void:
	#todo - change master volume
	pass # Replace with function body.
