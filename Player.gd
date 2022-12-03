class_name Player extends OnlinePlayer


export (int, 0, 10000) var speed: int = 500


var can_move: bool = false
var last_server_time: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	last_server_time = OS.get_system_time_msecs()


func _physics_process(delta: float) -> void:
	if !is_local or !can_move or !OS.is_window_focused():
		return
	
	var mouse_position := get_global_mouse_position()
	mouse_position.x = clamp(mouse_position.x, 0, 2560)
	mouse_position.y = clamp(mouse_position.y, 0, 1440)
	
	# Send my mouse position to the server
	var msg := Protobuf.create_client_input_msg(local_id, mouse_position.x, mouse_position.y)
	Client.send_data_to_server(msg, Online.Send.UNRELIABLE)
	
	if !Client.i_am_server():
		move(mouse_position)


func move(mouse_posn: Vector2) -> void:
	if (position - mouse_posn).length_squared() <= pow(speed / 60, 2):
		move_and_slide((mouse_posn - position) * 60)
	else:
		move_and_slide((mouse_posn - position).normalized() * speed)
	position = Vector2(int(position.x), int(position.y))


# Server receives input messages from Client and calls this function.
func on_receive_input_update(mouse_posn: Vector2) -> void:
	var now = OS.get_system_time_msecs()
	var i = 0
	while last_server_time < now and i < 3:
		move(mouse_posn)
		last_server_time += 17
		i += 1
	last_server_time = now
	
	# I've calculated my position. Send it to all clients.
	var msg := Protobuf.create_server_player_update_msg(local_id, position.x, position.y)
	Server.send_data_to_all_clients(msg, Online.Send.UNRELIABLE)


# Client receives player updates from Server and calls this function.
func on_receive_player_update(posn: Vector2) -> void:
	# TODO: Check physics here!
	if (position - posn).length_squared() >= 100:
		position = posn
	else:
		position = lerp(position, posn, 0.1)
