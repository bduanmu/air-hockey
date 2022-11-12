class_name Player extends OnlinePlayer


export (int, 0, 10000) var speed: int = 500


var can_move: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	if !is_local or !can_move:
		return
	# Send my mouse position to the server
	var msg := Protobuf.create_client_input_msg(local_id, get_global_mouse_position().x, get_global_mouse_position().y)
	Client.send_data_to_server(msg, Online.Send.UNRELIABLE)
	
	move(get_global_mouse_position())


func move(mouse_posn: Vector2) -> void:
	if (position - mouse_posn).length_squared() <= pow(speed / 60, 2):
		move_and_slide((mouse_posn - position) * 60)
	else:
		move_and_slide((mouse_posn - position).normalized() * speed)
	position = Vector2(int(position.x), int(position.y))


# Server receives input messages from Client and calls this function.
func on_receive_input_update(mouse_posn: Vector2) -> void:
	move(mouse_posn)
	
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
