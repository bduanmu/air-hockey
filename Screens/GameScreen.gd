class_name GameScreen extends Screen


signal quit_to_lobby


var lobby_data: Dictionary
var map: Map
var scores: Array
var players: Dictionary
var ball: RigidBody2D
var rng: RandomNumberGenerator
var time_remaining: int
var is_overtime: bool
var local_id: int


func create_new_game(lobby_data: Dictionary, lobby_id: int, host_id: int, lobby_seed: int) -> void:
	self.lobby_data = lobby_data
	
	rng = RandomNumberGenerator.new()
	rng.seed = lobby_seed
	
	# Connect to signals
	if !Server.is_connected("player_input_msg_received", self, "_on_player_input_msg_received"):
		Server.connect("player_input_msg_received", self, "_on_player_input_msg_received")
	if !Client.is_connected("player_update_msg_received", self, "_on_player_update_msg_received"):
		Client.connect("player_update_msg_received", self, "_on_player_update_msg_received")
	if !Client.is_connected("ball_update_msg_received", self, "_on_ball_update_msg_received"):
		Client.connect("ball_update_msg_received", self, "_on_ball_update_msg_received")
	if !Client.is_connected("powerup_collected_msg_received", self, "_on_powerup_collected_msg_received"):
		Client.connect("powerup_collected_msg_received", self, "_on_powerup_collected_msg_received")
	if !Server.is_connected("powerup_used_msg_received", self, "_on_powerup_used_msg_received"):
		Server.connect("powerup_used_msg_received", self, "_on_powerup_used_msg_received")
	if !Client.is_connected("powerup_used_msg_received", self, "_on_powerup_used_msg_received"):
		Client.connect("powerup_used_msg_received", self, "_on_powerup_used_msg_received")
	
	# Initialize the map
	map = lobby_data["map"]
	$WorldEnvironment.add_child(map)
	map.connect("goal_scored", self, "on_goal_scored")
	
	# Initialize players
#	for player in players:
#		players[player].queue_free()
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
	
	spawn_powerup(preload("res://PowerUps/SpeedPowerUp.tscn").instance(), 0)
	spawn_powerup(preload("res://PowerUps/SizePowerUp.tscn").instance(), 1)
	spawn_powerup(preload("res://PowerUps/SizePowerUp.tscn").instance(), 3)
	spawn_powerup(preload("res://PowerUps/SizePowerUp.tscn").instance(), 2)


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


func spawn_powerup(powerup: PowerUp, id: int) -> void:
	map.spawn_powerup(powerup, id)
	if Client.i_am_server():
		powerup.connect("collected", self, "_on_powerup_collected", [id])


func _on_powerup_collected(collector: Player, id: int) -> void:
	var msg := Protobuf.create_server_powerup_collected_msg(collector.local_id, id)
	Server.send_data_to_all_clients(msg, Online.Send.RELIABLE)


func _on_powerup_used_msg_received(msg: Dictionary, is_server: bool) -> void:
	if is_server:
		if players[msg["player_id"]].powerup != null and players[msg["player_id"]].powerup.is_valid:
			players[msg["player_id"]].powerup.is_valid = false
			Server.send_data_to_all_clients(Protobuf.create_server_powerup_used_msg(msg["player_id"]), Online.Send.RELIABLE)
	else:
		players[msg["player_id"]].use_powerup()
		print(msg["player_id"])


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
	get_parent().transition(ScreenManager.Screens.LOBBY)

func _on_player_input_msg_received(msg: Dictionary) -> void:
	if is_instance_valid(players[msg["id"]]):
		players[msg["id"]].on_receive_input_update(msg["direction"] & 8, msg["direction"] & 4, msg["direction"] & 2, msg["direction"] & 1)


func _on_player_update_msg_received(msg: Dictionary) -> void:
	if is_instance_valid(players[msg["id"]]):
		players[msg["id"]].on_receive_player_update(Vector2(msg["posn_x"], msg["posn_y"]))


func _on_ball_update_msg_received(msg: Dictionary) -> void:
	if is_instance_valid(ball):
		ball.on_receive_ball_update(Vector2(msg["posn_x"], msg["posn_y"]), Vector2(msg["vel_x"] - ball.max_speed, msg["vel_y"] - ball.max_speed))


func _on_powerup_collected_msg_received(msg: Dictionary) -> void:
	map.on_powerup_collected(players[msg["collector"]], msg["id"])
