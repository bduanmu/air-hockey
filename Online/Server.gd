extends Node2D # SET TO AUTOLOAD

# CUSTOM SIGNALS ###############################################################
signal player_input_msg_received
signal powerup_used_msg_received
################################################################################

var lobby_members: Array


func _ready() -> void:
	_connect_signals()


func _physics_process(_delta: float) -> void:
	_receive_network_data()


# INITIALIZERS #################################################################


func _connect_signals() -> void:
	Online.connect("session_request", self, "_on_session_request")


# FUNCTIONS ####################################################################


# Receives incoming network data
func _receive_network_data() -> void:
	var messages: Array = Online.receive_messages_on_channel(Online.Channel.SERVER, 32)
	for message in messages:
		on_data_received(Online.get_identity_id(message["identity"]), message["payload"])


func on_data_received(online_id: int, message: PoolByteArray) -> void:
	var msg := Protobuf.deserialize(message)
	if msg["type"] == Protobuf.Client.INITIATE_CONNECTION:
		var num_connected := 0
		for member in Client.lobby_members:
			if member.online_id == online_id:
				member.connected = true
			if member.connected:
				num_connected += 1
		if num_connected == len(Client.lobby_members):
			var start_msg := Protobuf.create_simple_msg(Protobuf.Server.START_GAME)
			send_data_to_all_clients(start_msg, Online.Send.RELIABLE_NO_NAGLE)
	else:
		handle_custom_message(online_id, msg)


func handle_custom_message(online_id: int, msg: Dictionary) -> void:
	if msg["type"] == Protobuf.Client.PLAYER_INPUT:
		emit_signal("player_input_msg_received", msg)
	elif msg["type"] == Protobuf.Client.POWERUP_USED:
		emit_signal("powerup_used_msg_received", msg, true)


func send_data_to_client(online_id: int, msg: PoolByteArray, flags: int) -> void:
	if Online.API == Online.NONE or online_id == Online.get_online_id():
		Client.on_data_received(online_id, msg)
	else:
		var result := Online.send_message_to_user(online_id, msg, flags, Online.Channel.CLIENT)
		if result != Online.Result.OK:
			print_debug("Failed sending data to client: ", result)


# Specify exclude_sender if I don't want to send message to sender
func send_data_to_all_clients(msg: PoolByteArray, flags: int, exclude_sender := -1) -> void:
	for lobby_member in Client.lobby_members:
		if lobby_member.online_id != exclude_sender:
			send_data_to_client(lobby_member.online_id, msg, flags)


# CALLBACKS ####################################################################


# Accept new incoming connections
func _on_session_request(identity: String) -> void:
	Online.accept_session_with_user(Online.get_identity_id(identity))
