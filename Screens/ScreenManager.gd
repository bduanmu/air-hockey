class_name ScreenManager extends Node


enum Screens {
	START,
	SETTINGS,
	LOBBY,
	GAME
}


onready var screens: Array = [
	$StartScreen,
	$SettingsScreen,
	$LobbyScreen,
	$GameScreen
]
var current_screen


func _ready() -> void:
	current_screen = screens[Screens.START]


func transition(next_screen_index: int) -> void:
	current_screen.hide()
	current_screen = screens[next_screen_index]
	current_screen.show()
