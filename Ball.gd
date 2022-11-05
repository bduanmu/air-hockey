extends RigidBody2D


export(int, 1, 100000) var max_speed


var last_server_position: Vector2
var last_server_velocity: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	if Client.i_am_server():
		var msg := Protobuf.create_server_ball_update_msg(position.x, position.y, linear_velocity.x + max_speed, linear_velocity.y + max_speed)
		Server.send_data_to_all_clients(msg, Online.Send.UNRELIABLE)


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if Client.i_am_server():
		if state.linear_velocity.length_squared() > max_speed * max_speed:
			state.set_linear_velocity(state.linear_velocity.normalized() * max_speed)
		state.set_linear_velocity(Vector2(int(state.linear_velocity.x), int(state.linear_velocity.y)))
	else:
		if last_server_velocity != max_speed * Vector2(2, 2):
			state.set_linear_velocity(last_server_velocity)
			last_server_velocity = max_speed * Vector2(2, 2)
		if last_server_position != Vector2(-100, -100) and (state.transform.get_origin() - last_server_position).length_squared() >= 16:
			state.transform.origin = last_server_position
			last_server_position = Vector2(-100, -100)


func on_receive_ball_update(posn: Vector2, velocity: Vector2) -> void:
	last_server_position = posn
	last_server_velocity = velocity
