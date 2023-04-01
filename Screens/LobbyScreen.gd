extends Screen


signal start_game


var lobby_id: int setget set_lobby_id
var game_starting: bool


onready var lobby_members := $"%LobbyMemberContainer".get_children()
onready var _lobby_chat := $"%LobbyChat"
onready var _line_edit := $"%LineEdit"


func _ready() -> void:
	_connect_signals()


# INITIALIZERS #################################################################


func _connect_signals() -> void:
	Online.connect("lobby_entered", self, "_on_lobby_entered")
	Online.connect("lobby_data_update", self, "_on_lobby_data_update")
	Online.connect("lobby_chat_update", self, "_on_lobby_chat_update")
	Online.connect("lobby_message", self, "_on_lobby_message")
	
	connect("start_game", Client, "_on_game_started")


# FUNCTIONS ####################################################################


func connect_signals(node: Node) -> void:
	connect("start_game", node, "_on_game_started")


func _update_lobby() -> void:
	var num_members := Online.get_num_lobby_members(lobby_id)
	if Online.get_lobby_owner(lobby_id) == Online.get_online_id():
		$"%PlayButton".disabled = false
	else:
		$"%PlayButton".disabled = true
	for i in range(Online.MAX_PLAYERS):
		if i < num_members:
			lobby_members[i].online_id = Online.get_lobby_member_by_index(lobby_id, i)
			lobby_members[i].member_name = Online.get_friend_persona_name(lobby_members[i].online_id)
			lobby_members[i].show()
		else:
			lobby_members[i].online_id = 0
			lobby_members[i].member_name = "Empty"
			lobby_members[i].hide()


func _create_lobby_data() -> Dictionary:
	var members = []
	var num_members := Online.get_num_lobby_members(lobby_id)
	for i in range(num_members):
		members.append(lobby_members[i])
	
	var lobby_data: Dictionary = {
		"map": preload("res://Maps/Map.tscn").instance(),
		"members": members,
	}
	
	return lobby_data


# CALLBACKS ####################################################################


func _on_play_button_pressed() -> void:
	if game_starting:
		return
	game_starting = true
	var lobby_seed := randi()
	Online.set_lobby_data(lobby_id, "game_starting", str(lobby_seed))
	if Online.API == Online.NONE: # Offline mode
		emit_signal("start_game", _create_lobby_data(), 0, 0, lobby_seed)


func _on_back_button_pressed() -> void:
	Online.leave_lobby(lobby_id)
	self.lobby_id = 0
	_lobby_chat.text = ""
	emit_signal("back_button_pressed")
	get_parent().transition(Screens.START)


# I entered the lobby.
func _on_lobby_entered(lobby_id: int) -> void:
	self.lobby_id = lobby_id
	_update_lobby()


# Someone else entered or left the lobby.
func _on_lobby_chat_update(_lobby_id: int, changed_id: int, chat_state: int) -> void:
	if chat_state == Online.ChatMemberStateChange.ENTERED:
		_update_lobby()
		_lobby_chat.append_bbcode("[color=#FFFF99]" + Online.get_friend_persona_name(changed_id) + "[/color] joined.\n")
	else:
		_update_lobby()
		_lobby_chat.append_bbcode("[color=#FFFF99]" + Online.get_friend_persona_name(changed_id) + "[/color] left.\n")


func _on_lobby_data_update(_lobby_id: int, member_id: int) -> void:
	_update_lobby()
	print(lobby_id,"hwkbafj")
	if lobby_id == member_id: # The lobby made the change
		var lobby_seed := Online.get_lobby_data(lobby_id, "game_starting")
		if lobby_seed != "":
			hide()
			game_starting = false
			var host_id := Online.get_lobby_owner(lobby_id)
			emit_signal("start_game", _create_lobby_data(), lobby_id, host_id, int(lobby_seed))
	else:
		pass


func _on_lobby_message(_lobby_id: int, sender_id: int, msg: String, _chat_type: int) -> void:
	if sender_id == 0: # Offline
		_lobby_chat.append_bbcode("[color=#FFFF99]Me:[/color] " + msg + "\n")
	else:
		_lobby_chat.append_bbcode("[color=#FFFF99]" + Online.get_friend_persona_name(sender_id).substr(0, 20) + ":[/color] " + msg + "\n")


func _on_invite_button_pressed() -> void:
	Online.activate_invite_dialog(lobby_id)


func _on_text_entered(new_text: String) -> void:
	if new_text == "":
		return
	Online.send_lobby_chat_msg(lobby_id, new_text)
	if Online.API == Online.NONE:
		_on_lobby_message(0, 0, new_text, 1)
	_line_edit.text = ""


# SETGETTERS ###################################################################


func set_lobby_id(id: int) -> void:
	lobby_id = id
