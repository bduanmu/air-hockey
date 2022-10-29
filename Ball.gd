extends RigidBody2D


export(int, 1, 100000) var max_speed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	var msg := Protobuf.create_server_ball_update_msg(position.x, position.y)
	Server.send_data_to_all_clients(msg, Online.Send.UNRELIABLE)


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if state.linear_velocity.length_squared() > max_speed * max_speed:
		state.set_linear_velocity(state.linear_velocity.normalized() * max_speed)
