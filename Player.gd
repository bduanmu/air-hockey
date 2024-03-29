class_name Player extends OnlinePlayer


export (int, 0, 400) var max_speed: int = 200
export (int) var accel_strength: int
export (int) var recoil_strength: int = 500


var can_move: bool = false
var last_server_time: int
var velocity: Vector2
var powerup: PowerUp
var powerup_indicator: Sprite


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"%Sprite".scale *= ($CollisionShape2D.shape.radius * 2) / 256
	if local_id == 2:
		$"%InnerCircle".modulate = Color.red * 1.3
	else:
		$"%InnerCircle".modulate = Color.blue * 1.3
	last_server_time = OS.get_system_time_msecs()
	$"%ShotTimer".connect("timeout", self, "_on_shot_timer_timeout")
	
	powerup_indicator = Sprite.new()
	add_child(powerup_indicator)
	powerup_indicator.hide()


func _input(event: InputEvent) -> void:
	if !is_local:
		return
	if event.is_action_released("use_powerup"):
		if is_instance_valid(powerup):
			powerup_indicator.hide()
			
		var msg := Protobuf.create_client_powerup_used_msg(local_id, get_global_mouse_position().x, get_global_mouse_position().y)
		Client.send_data_to_server(msg, Online.Send.RELIABLE)
	elif event.is_action_pressed("use_powerup"):
		if is_instance_valid(powerup):
			powerup_indicator.show()
	elif event.is_action_released("shoot"):
		var msg := Protobuf.create_client_shot_msg(local_id, get_global_mouse_position().x, get_global_mouse_position().y)
		Client.send_data_to_server(msg, Online.Send.RELIABLE)
		start_shot_cooldown()
		$"%ShotIndicator".hide()
	elif event.is_action_pressed("shoot"):
		$"%ShotIndicator".show()


func _process(delta) -> void:
	$"%ShotIndicator".look_at(get_global_mouse_position())
	if is_instance_valid(powerup):
		powerup.update_indicator(self)


func _physics_process(delta: float) -> void:
	if !is_local or !OS.is_window_focused():
		return
	
	var up := 1 if Input.is_action_pressed("move_up") else 0
	var down := 1 if Input.is_action_pressed("move_down") else 0
	var left := 1 if Input.is_action_pressed("move_left") else 0
	var right := 1 if Input.is_action_pressed("move_right") else 0
	
#	var mouse_position := get_global_mouse_position()
#	mouse_position.x = clamp(mouse_position.x, 0, 2560)
#	mouse_position.y = clamp(mouse_position.y, 0, 1440)
	
	# Send my mouse position to the server
	var msg := Protobuf.create_client_input_msg(local_id, up << 3 | down << 2 | left << 1 | right)
	Client.send_data_to_server(msg, Online.Send.UNRELIABLE)
	
	if !Client.i_am_server() and can_move:
		move(up, down, left, right, delta)


func move(up: int, down: int, left: int, right: int, delta: float) -> void:
	velocity += Vector2(right - left, down - up).normalized() * accel_strength * delta
	var friction: Vector2 = - velocity.normalized() * 25 * delta
	velocity += friction
#	if (position - mouse_posn).length_squared() <= pow(speed / 60, 2):
#		move_and_slide((mouse_posn - position) * 60)
#	else:
#		move_and_slide(direction * speed)
	if velocity.length_squared() > max_speed * max_speed:
		velocity = velocity.move_toward(velocity.limit_length(max_speed), accel_strength * delta)
	move_and_slide(velocity)
	
	for i in range(get_slide_count()):
		var collision = get_slide_collision(i)
		if collision.collider.collision_layer & Global.Layer.WALL:
			velocity = velocity.slide(collision.normal)
	
#	position = Vector2(int(position.x), int(position.y))


func is_shot_on_cooldown() -> bool:
	return !$"%ShotTimer".is_stopped()


func start_shot_cooldown() -> void:
	if !is_shot_on_cooldown():
		$"%ShotTimer".start()
		$"%ShotIndicator".modulate = Color("827c7c7c")
		# Shot is unavailable


func _on_shot_timer_timeout() -> void:
	# Shot is available
	$"%ShotIndicator".modulate = Color("823580f6")


func recoil(direction: Vector2) -> void:
	velocity += direction * recoil_strength


func use_powerup(mouse_position: Vector2) -> void: #Validation complete
	powerup.use(self, mouse_position)
	powerup = null


# Server receives input messages from Client and calls this function.
func on_receive_input_update(up: int, down: int, left: int, right: int) -> void:
	var now = OS.get_system_time_msecs()
	var i = 0
	while last_server_time < now and i < 3:
		move(up, down, left, right, get_physics_process_delta_time())
		last_server_time += get_physics_process_delta_time()
		i += 1
	last_server_time = now
	
	# I've calculated my position. Send it to all clients.
	var msg := Protobuf.create_server_player_update_msg(local_id, position.x, position.y, velocity.x + 2048, velocity.y + 2048)
	Server.send_data_to_all_clients(msg, Online.Send.UNRELIABLE)


# Client receives player updates from Server and calls this function.
func on_receive_player_update(posn: Vector2, velocity: Vector2) -> void:
	# TODO: Check physics here!
#	self.velocity = velocity
	if (position - posn).length_squared() >= 9:
		position = posn
	else:
		position = lerp(position, posn, 0.1)
