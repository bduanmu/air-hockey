extends Node2D # SET TO AUTOLOAD


signal game_authenticated
# CUSTOM SIGNALS ###############################################################
signal player_update_msg_received
signal ball_update_msg_received
signal powerup_collected_msg_received
################################################################################


enum GameState {
	CREATING_LOBBY,
	JOINING_LOBBY,
	JOINED_LOBBY,
	CONNECTING,
	CONNECTION_FAILURE,
	CONNECTED,
}


var game_state: int
var server_id: int
var lobby_members: Array
var lobby_seed: int


func _ready() -> void:
	Online.init_relay_network_access()
	_connect_signals()


func _physics_process(_delta: float) -> void:
	_receive_network_data()
	Online.run_callbacks()
	
	if game_state == GameState.CONNECTING:
		_initiate_server_connection()


# INITIALIZERS #################################################################


func _connect_signals() -> void:
	# Lobby signals
	Online.connect("lobby_join_requested", self, "_on_lobby_join_requested")
	
	# Connection signals
#	Online.connect("session_request", self, "_on_session_request")


# FUNCTIONS ####################################################################


func _receive_network_data() -> void:
	var messages = Online.receive_messages_on_channel(Online.Channel.CLIENT, 32)
	for message in messages:
		on_data_received(Online.get_identity_id(message["identity"]), message["payload"])


func on_data_received(online_id: int, message: PoolByteArray) -> void:
	var msg := Protobuf.deserialize(message)
	if msg["type"] == Protobuf.Server.START_GAME:
		print_debug("received authenticate msg from: ", online_id)
		online_id = Online.get_online_id()
		if game_state != GameState.CONNECTED:
			emit_signal("game_authenticated", lobby_seed)
		set_game_state(GameState.CONNECTED)
	else:
		handle_custom_message(online_id, msg)


func handle_custom_message(online_id: int, msg: Dictionary) -> void:
	if msg["type"] == Protobuf.Server.PLAYER_UPDATE:
		emit_signal("player_update_msg_received", msg)
	elif msg["type"] == Protobuf.Server.BALL_UPDATE:
		emit_signal("ball_update_msg_received", msg)
	elif msg["type"] == Protobuf.Server.POWERUP_COLLECTED:
		emit_signal("powerup_collected_msg_received", msg)
	


#func disconnect_from_server() -> void:
#	if connected_status != Online.Status.CLIENT_NOT_CONNECTED:
#		connected_status = Online.Status.CLIENT_NOT_CONNECTED
#	if connected_server != Online.NetworkConnection.INVALID:
#		Online.close_connection(connected_server, Online.DisconnectReason.CLIENT_DISCONNECT, "Invalid network connection")
#	game_server_id = 0
#	connected_server = Online.NetworkConnection.INVALID


func set_game_state(state: int) -> void:
	if game_state == state:
		return
	game_state = state


const SERVER_CONNECT_RETRY_TIME := 5000
var _server_connect_time: int


# Only called when game_state == GameState.CONNECTING
func _initiate_server_connection(first_time := false) -> void:
	if first_time:
		_server_connect_time = SERVER_CONNECT_RETRY_TIME
		for member in lobby_members:
			member.connected = false
	if _server_connect_time >= SERVER_CONNECT_RETRY_TIME:
		_server_connect_time = 0
		var msg := Protobuf.create_simple_msg(Protobuf.Client.INITIATE_CONNECTION)
		send_data_to_server(msg, Online.Send.RELIABLE_NO_NAGLE)
	_server_connect_time += int(get_physics_process_delta_time() * 1000)


func send_data_to_server(msg: PoolByteArray, flags: int) -> void:
	if Online.API == Online.NONE or Online.get_online_id() == server_id:
		Server.on_data_received(server_id, msg)
	else:
		var result = Online.send_message_to_user(server_id, msg, flags, Online.Channel.SERVER)
		if result != Online.Result.OK:
			print_debug("Failed sending data to server: ", result)


# Use send_data_to_client if P2P model. Otherwise use send_data_to_server for Client/Server model!

#func send_data_to_client(online_id: int, msg: PoolByteArray, flags: int) -> void:
#	if Online.API == Online.NONE or online_id == Online.get_online_id():
#		Client.on_data_received(online_id, msg)
#	else:
#		var result := Online.send_message_to_user(online_id, msg, flags, Online.Channel.CLIENT)
#		if result != Online.Result.OK:
#			print_debug("Failed sending data to client: ", result)
#
#
## Specify exclude_sender if I don't want to send message to sender
#func send_data_to_all_clients(msg: PoolByteArray, flags: int, exclude_myself := true) -> void:
#	for lobby_member in Client.lobby_members:
#		if exclude_myself and lobby_member.online_id != Online.get_online_id() or !exclude_myself:
#			send_data_to_client(lobby_member.online_id, msg, flags)


func i_am_server() -> bool:
	return server_id == Online.get_online_id()


# CALLBACKS ####################################################################


# LOBBY CALLBACKS ##############################################################
func _on_lobby_join_requested(lobby_id: int, _friend_id: int) -> void:
	Online.join_lobby(lobby_id)
	set_game_state(GameState.JOINING_LOBBY)


func _on_game_started(lobby_data: Dictionary, _lobby_id: int, host_id: int, lobby_seed: int) -> void:
	self.lobby_members = lobby_data["members"]
	self.lobby_seed = lobby_seed
	for member in lobby_members:
		Online.add_identity(member.online_id)
		Online.set_identity_id(member.online_id, false)
		Online.set_identity_id(member.online_id, true)
	server_id = host_id
	set_game_state(GameState.CONNECTING)
	_initiate_server_connection(true)


## Receive basic server info from the server after we initiate a connection.
#func on_receive_server_info(game_server_id: int) -> void:
#	connected_status = Online.Status.CLIENT_CONNECTED_PENDING_AUTH
#	self.game_server_id = game_server_id
#	Online.get_connection_info(connected_server)
#	var msg # TODO: create the ClientBeginAuth message
#	send_server_data(msg, Online.Send.RELIABLE)
#
#
#func on_receive_server_auth_response(success: bool, player_index: int) -> void:
#	if !success:
#		set_game_state(GameState.CONNECTION_FAILURE)
#		disconnect_from_server()
#	else:
#		# Ignore duplicate message.
#		if connected_status == Online.Status.CLIENT_CONNECTED_AND_AUTHENTICATED and \
#				player_index == self.player_index:
#			return
#		self.player_index = player_index
#		connected_status = Online.Status.CLIENT_CONNECTED_AND_AUTHENTICATED
#
#
#func on_receive_server_full_response() -> void:
#	set_game_state(GameState.CONNECTION_FAILURE)
#	disconnect_from_server()
