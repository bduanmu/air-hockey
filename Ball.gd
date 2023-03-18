class_name Ball extends RigidBody2D


export(int, 1, 100000) var max_speed


onready var last_server_position: Vector2 = Vector2(2560 / 2, 820)
onready var last_server_velocity: Vector2

var trail_length: int = 30


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite.scale = Vector2(1, 1) * ($CollisionShape2D.shape.radius * 2) / 256
	$Line2D.points = []
	$Line2D.set_as_toplevel(true)


func _process(delta: float) -> void:
	$Line2D.add_point(position, 0)
	if len($Line2D.points) > trail_length:
		$Line2D.remove_point(len($Line2D.points) - 1)
	$Sprite.modulate = lerp($Sprite.modulate, Color.white * 1.13, 0.03)


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
		if last_server_position != Vector2(-100, -100):
			if (state.transform.get_origin() - last_server_position).length_squared() >= 100:
				state.transform.origin = last_server_position
			elif (state.transform.get_origin() - last_server_position).length_squared() >= 4:
				state.transform.origin = lerp(state.transform.origin, last_server_position, 0.1)
			last_server_position = Vector2(-100, -100)


func on_receive_ball_update(posn: Vector2, velocity: Vector2) -> void:
	last_server_position = posn
	last_server_velocity = velocity


func _on_body_entered(body: Node) -> void:
#	var velocity = Vector2(0, 0)
#	if body is KinematicBody2D:
#		velocity = body.direction
	$Sprite.modulate = Color.white * min(1.3, 1)
