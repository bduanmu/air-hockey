class_name GameScreen extends Screen


var map: Map
var scores: Array
var players: Dictionary
var ball: RigidBody2D
var rng: RandomNumberGenerator
var time_remaining: int
var is_overtime: bool
var local_id: int


func create_new_game(lobby_data: Dictionary, lobby_id: int, host_id: int, lobby_seed: int) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = lobby_seed
	
	# Connect to signals
	Server.connect("player_input_msg_received", self, "_on_player_input_msg_received")
	Client.connect("player_update_msg_received", self, "_on_player_update_msg_received")
	Client.connect("ball_update_msg_received", self, "_on_ball_update_msg_received")
	
	# Initialize the map
	map = lobby_data["map"]
	$WorldEnvironment.add_child(map)
	map.connect("goal_scored", self, "on_goal_scored")
	
	# Initialize players
	for player in players:
		players[player].queue_free()
	players = {}
	
	for i in range(lobby_data["members"].size()):
		var player = preload("res://Player.tscn").instance()
		player.local_id = i + 1 # Use +1 because invalid can be 0.
		player.online_id = lobby_data["members"][i].online_id
		if player.online_id == Online.get_online_id():
			player.is_local = true
			local_id = i
		map.add_child(player)
		players[player.local_id] = player
	
	$"%Timer".start()
	$"%Timer".set_paused(true)
	time_remaining = 5
	
	scores = [0, 0]
	is_overtime = false
	reset()


func reset() -> void:
	if ball != null:
		ball.queue_free()
	
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
	if players.size() > 1:
		players[players.keys()[1]].can_move = true
	
	ball = preload("res://Ball.tscn").instance()
	ball.position = Vector2(2560 / 2, 820)
	map.add_child(ball)


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
			$"%OvertimeLabel".show()
		else:
			declare_winner()


func declare_winner() -> void:
	if scores[local_id - 1] < scores[local_id % 2]:
		print("win")
	else:
		print("lose")


func _on_player_input_msg_received(msg: Dictionary) -> void:
	players[msg["id"]].on_receive_input_update(Vector2(msg["posn_x"], msg["posn_y"]))


func _on_player_update_msg_received(msg: Dictionary) -> void:
	players[msg["id"]].on_receive_player_update(Vector2(msg["posn_x"], msg["posn_y"]))


func _on_ball_update_msg_received(msg: Dictionary) -> void:
	ball.on_receive_ball_update(Vector2(msg["posn_x"], msg["posn_y"]), Vector2(msg["vel_x"] - ball.max_speed, msg["vel_y"] - ball.max_speed))
