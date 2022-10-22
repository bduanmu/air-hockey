class_name GameScreen extends Screen


var map: Map


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func create_new_game(lobby_data: Dictionary) -> void:
	$WorldEnvironment.add_child(lobby_data["Map"])
	map = lobby_data["Map"]
	var player1 = preload("res://Player.tscn").instance()
	player1.position = Vector2(320, 820)
	map.add_child(player1)
#	var player2 = preload("res://Player.tscn").instance()
#	player2.position = Vector2(2560 - 320, 820)
#	map.add_child(player2)
	var ball = preload("res://Ball.tscn").instance()
	ball.position = Vector2(2560 / 2, 820)
	map.add_child(ball)
