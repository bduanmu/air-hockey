class_name GameScreen extends Screen


var map: Map
var scores: Array
var players: Array = [null, null]
var ball: RigidBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func create_new_game(lobby_data: Dictionary) -> void:
	$WorldEnvironment.add_child(lobby_data["Map"])
	map = lobby_data["Map"]
	players[0] = preload("res://Player.tscn").instance()
	map.add_child(players[0])
#	var players[1] = preload("res://Player.tscn").instance()
#	map.add_child(players[1])
	scores = [0, 0]
	reset()
	map.connect("goal_scored", self, "on_goal_scored")


func reset() -> void:
	if ball != null:
		ball.queue_free()
	ball = preload("res://Ball.tscn").instance()
	map.add_child(ball)
	ball.position = Vector2(2560 / 2, 820)
	players[0].position = Vector2(320, 820)
#	players[1].position = Vector2(2560 - 320, 820)


func on_goal_scored(side: int) -> void:
	scores[side] += 1
	reset()
