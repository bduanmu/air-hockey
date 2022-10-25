class_name GameScreen extends Screen


var map: Map
var scores: Array
var players: Dictionary
var ball: RigidBody2D
var rng: RandomNumberGenerator


func create_new_game(lobby_data: Dictionary, lobby_id: int, host_id: int, lobby_seed: int) -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = lobby_seed
	
	# Connect to signals
	Server.connect("player_input_msg_received", self, "_on_player_input_msg_received")
	Client.connect("player_update_msg_received", self, "_on_player_update_msg_received")
	
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
		map.add_child(player)
		players[player.local_id] = player
	
	scores = [0, 0]
	reset()


func reset() -> void:
	if ball != null:
		ball.queue_free()
	ball = preload("res://Ball.tscn").instance()
	map.call_deferred("add_child", ball)
	ball.set_deferred("position", Vector2(2560 / 2, 820))
	
	players[players.keys()[0]].position = Vector2(320, 820)
	players[players.keys()[1]].position = Vector2(2560 - 320, 820)


func on_goal_scored(side: int) -> void:
	scores[side] += 1
	reset()


func _on_player_input_msg_received(msg: Dictionary) -> void:
	players[msg["id"]].on_receive_input_update(Vector2(msg["posn_x"], msg["posn_y"]))


func _on_player_update_msg_received(msg: Dictionary) -> void:
	players[msg["id"]].on_receive_player_update(Vector2(msg["posn_x"], msg["posn_y"]))
