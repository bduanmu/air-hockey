class_name GameScreen extends Screen


signal quit_to_lobby


export (PackedScene) var projectile_scene: PackedScene


var lobby_data: Dictionary
var map: Map
var scores: Array
var players: Dictionary
var ball: RigidBody2D
var rng: RandomNumberGenerator
var time_remaining: int
var is_overtime: bool
var local_id: int

#current_powerups holds the PowerUp.Type. A value of -1 means the power up is collected
var current_powerups: Array = []


func create_new_game(lobby_data: Dictionary, lobby_id: int, host_id: int, lobby_seed: int) -> void:
	self.lobby_data = lobby_data
	
	rng = RandomNumberGenerator.new()
	rng.seed = lobby_seed
	
	# Connect to signals
	if !Server.is_connected("player_input_msg_received", self, "_on_player_input_msg_received"):
		Server.connect("player_input_msg_received", self, "_on_player_input_msg_received")
	if !Client.is_connected("player_update_msg_received", self, "_on_player_update_msg_received"):
		Client.connect("player_update_msg_received", self, "_on_player_update_msg_received")
	if !Server.is_connected("shot_msg_received", self, "_on_shot_msg_received"):
		Server.connect("shot_msg_received", self, "_on_shot_msg_received")
	if !Client.is_connected("shot_msg_received", self, "_on_shot_msg_received"):
		Client.connect("shot_msg_received", self, "shoot")
	if !Client.is_connected("ball_update_msg_received", self, "_on_ball_update_msg_received"):
		Client.connect("ball_update_msg_received", self, "_on_ball_update_msg_received")
	if !Client.is_connected("powerup_collected_msg_received", self, "_on_powerup_collected_msg_received"):
		Client.connect("powerup_collected_msg_received", self, "_on_powerup_collected_msg_received")
	if !Server.is_connected("powerup_used_msg_received", self, "_on_powerup_used_msg_received"):
		Server.connect("powerup_used_msg_received", self, "_on_powerup_used_msg_received")
	if !Client.is_connected("powerup_used_msg_received", self, "_on_powerup_used_msg_received"):
		Client.connect("powerup_used_msg_received", self, "_on_powerup_used_msg_received")
	if !Client.is_connected("powerup_spawned_msg_received", self, "_on_powerup_spawned_msg_received"):
		Client.connect("powerup_spawned_msg_received", self, "_on_powerup_spawned_msg_received")
	
	# Initialize the map
	map = lobby_data["map"]
	$WorldEnvironment.add_child(map)
	map.connect("goal_scored", self, "on_goal_scored")
	
	# Initialize players
	players = {}
	
	$"%Scoreboard".show()
	$"%TimerLabel".text = "5:00"
	$"%OvertimeLabel".modulate = Color.transparent
	$"%Timer".start()
	$"%Timer".set_paused(true)
	time_remaining = 5 * 60 * 0 + 20
	
	$"%LeftScore".text = "0"
	$"%RightScore".text = "0"
	scores = [0, 0]
	
	is_overtime = false
	reset()
	
	current_powerups.resize(map.get_node("%PowerUpLocations").get_child_count())
	for i in range(current_powerups.size()):
		current_powerups[i] = -1


func reset() -> void:
	if is_instance_valid(ball):
		ball.queue_free()
	
	for player in players:
		players[player].queue_free()
	
	for i in range(lobby_data["members"].size()):
		var player = preload("res://Player.tscn").instance()
		player.local_id = i + 1 # Use +1 because invalid can be 0.
		player.online_id = lobby_data["members"][i].online_id
		if player.online_id == Online.get_online_id():
			player.is_local = true
			local_id = i
		map.add_child(player)
		players[player.local_id] = player
	
	players[players.keys()[0]].position = Vector2(320, 820)
	players[players.keys()[0]].get_node("Camera2D").reset_smoothing()
	players[players.keys()[0]].can_move = false
	if players.size() > 1:
		players[players.keys()[1]].position = Vector2(2560 - 320, 820)
		players[players.keys()[1]].get_node("Camera2D").reset_smoothing()
		players[players.keys()[1]].can_move = false
	
	yield(get_tree().create_timer(3), "timeout")
	$"%Timer".set_paused(false)
	
	players[players.keys()[0]].can_move = true
	players[players.keys()[0]].last_server_time = OS.get_system_time_msecs()
	if players.size() > 1:
		players[players.keys()[1]].can_move = true
		players[players.keys()[1]].last_server_time = OS.get_system_time_msecs()
	
	ball = preload("res://Ball.tscn").instance()
	ball.position = Vector2(2560 / 2, 820)
	map.add_child(ball)
	
	$"%SpawnPowerUpTimer".start(max(5, rng.randfn(15, 5)))


func shoot(msg: Dictionary) -> void:
	players[msg["id"]].start_shot_cooldown()
	
	var direction: Vector2 = (Vector2(msg["mouse_x"], msg["mouse_y"]) - players[msg["id"]].position).normalized()
	players[msg["id"]].recoil(-direction)
	
	var projectile: Projectile = projectile_scene.instance()
	projectile.position = players[msg["id"]].position
	projectile.linear_velocity = direction * projectile.speed
	add_child(projectile)


func spawn_powerup(powerup: PowerUp, index: int) -> void:
	powerup.index = index
	map.spawn_powerup(powerup, index)
	if Client.i_am_server():
		powerup.connect("collected", self, "_on_powerup_collected", [index])


func _on_spawn_powerup_timer_timeout():
	if !Client.i_am_server():
		return
	for i in range(current_powerups.size()):
		if current_powerups[i] == -1:
			var random_powerup = rng.randi_range(0, PowerUp.Type.COUNT - 1)
			while current_powerups.has(random_powerup):
				random_powerup = (random_powerup + 1) % PowerUp.Type.COUNT
			current_powerups[i] = random_powerup
			var msg := Protobuf.create_server_powerup_spawned_msg(random_powerup, i)
			Server.send_data_to_all_clients(msg, Online.Send.RELIABLE)


func _on_powerup_collected(collector: Player, id: int) -> void:
	var msg := Protobuf.create_server_powerup_collected_msg(collector.local_id, id)
	Server.send_data_to_all_clients(msg, Online.Send.RELIABLE)
	# When collected, set the powerup to be -1. 
	current_powerups[id] = -1


func on_goal_scored(side: int) -> void:
	scores[int(side == 0)] += 1
	if side == 0:
		$"%RightScore".text = str(scores[1])
	else: 
		$"%LeftScore".text = str(scores[0])
	$"%Timer".set_paused(true)
	if is_overtime:
		declare_winner()
	else:
		reset()


func _on_timer_timeout() -> void:
	if is_overtime:
		time_remaining += 1
	else:
		time_remaining -= 1
	$"%TimerLabel".text = "%d:%02d" % [time_remaining / 60, time_remaining % 60]
	if time_remaining == 0: 
		if scores[0] == scores[1]:
			is_overtime = true
			$"%OvertimeLabel".modulate = Color.white
		else:
			declare_winner()


func declare_winner() -> void:
	get_tree().paused = true
	if scores[local_id - 1] < scores[local_id % 2]:
		print("win")
	else:
		print("lose")
	$"%TransitionTimer".start()


func _quit_to_lobby() -> void:
	$"%Scoreboard".hide()
	map.queue_free()
	get_tree().paused = false
	get_parent().transition(Screens.LOBBY)

func _on_player_input_msg_received(msg: Dictionary) -> void:
	if is_instance_valid(players[msg["id"]]):
		if !players[msg["id"]].can_move:
			return
		players[msg["id"]].on_receive_input_update((msg["direction"] & 8) >> 3, (msg["direction"] & 4) >> 2, (msg["direction"] & 2) >> 1, msg["direction"] & 1)


func _on_player_update_msg_received(msg: Dictionary) -> void:
	if is_instance_valid(players[msg["id"]]):
		players[msg["id"]].on_receive_player_update(Vector2(msg["posn_x"], msg["posn_y"]), Vector2(msg["vel_x"] - 2048, msg["vel_y"] - 2048))


func _on_shot_msg_received(msg: Dictionary) -> void:
	if is_instance_valid(players[msg["id"]]):
		if players[msg["id"]].is_shot_on_cooldown() or !players[msg["id"]].can_move:
			return
		players[msg["id"]].start_shot_cooldown()
		var client_msg = Protobuf.create_server_shot_msg(msg["id"], msg["mouse_x"], msg["mouse_y"])
		Server.send_data_to_all_clients(client_msg, Online.Send.RELIABLE)


func _on_ball_update_msg_received(msg: Dictionary) -> void:
	if is_instance_valid(ball):
		ball.on_receive_ball_update(Vector2(msg["posn_x"], msg["posn_y"]), Vector2(msg["vel_x"] - ball.max_speed, msg["vel_y"] - ball.max_speed))


func _on_powerup_collected_msg_received(msg: Dictionary) -> void:
	map.on_powerup_collected(players[msg["collector"]], msg["id"])


func _on_powerup_used_msg_received(msg: Dictionary, is_server: bool) -> void:
	if is_server:
		if !players[msg["player_id"]].can_move:
			return
		if players[msg["player_id"]].powerup != null and players[msg["player_id"]].powerup.is_valid:
			players[msg["player_id"]].powerup.is_valid = false
			Server.send_data_to_all_clients(Protobuf.create_server_powerup_used_msg(msg["player_id"]), Online.Send.RELIABLE)
	else:
		players[msg["player_id"]].use_powerup()


func _on_powerup_spawned_msg_received(msg: Dictionary) -> void:
	spawn_powerup(Global.power_ups[msg["powerup_type"]].instance(), msg["powerup_index"])
