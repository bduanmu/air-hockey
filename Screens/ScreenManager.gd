class_name ScreenManager extends Node


onready var screens: Array = [
	preload("res://Screens/StartScreen.tscn"),
	preload("res://Screens/SettingsScreen.tscn"),
	preload("res://Screens/LobbyScreen.tscn"),
	preload("res://Screens/GameScreen.tscn"),
]


var current_screen
var lobby_id: int


func _ready() -> void:
	Online.init()
	Client.connect("game_authenticated", self, "_on_game_authenticated")
	Online.connect("lobby_entered", self, "_on_lobby_entered")
	current_screen = $StartScreen
	current_screen.connect_signals(self)
	randomize()


func transition(next_screen_index: int) -> void:
	current_screen.queue_free()
	current_screen = screens[next_screen_index].instance()
	add_child(current_screen)
	current_screen.connect_signals(self)
	if next_screen_index == Screen.Screens.LOBBY:
		current_screen._on_lobby_entered(lobby_id)


func to_start_screen() -> void:
	transition(Screen.Screens.START)


func _on_game_authenticated(lobby_seed: int) -> void:
#	transition(Screen.Screens.GAME)
	pass


func _on_game_started(lobby_data: Dictionary, lobby_id: int, host_id: int, lobby_seed: int) -> void:
	self.lobby_id = lobby_id
	transition(Screen.Screens.GAME)
	current_screen.create_new_game(lobby_data, lobby_id, host_id, lobby_seed)


func _on_settings_button_pressed() -> void:
	transition(Screen.Screens.SETTINGS)


func _on_play_button_pressed() -> void:
	Online.create_lobby(Online.LobbyType.PUBLIC, 8)
	Client.set_game_state(Client.GameState.CREATING_LOBBY)
	transition(Screen.Screens.LOBBY)


func _on_lobby_entered(lobby_id: int) -> void:
	self.lobby_id = lobby_id
	transition(Screen.Screens.LOBBY)
