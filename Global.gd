extends Node


enum Layer {
	PLAYER = 1,
	BALL = 2,
	POWERUP = 4,
	WALL = 8,
}


var power_ups: Array = [
	preload("res://PowerUps/SizePowerUp.tscn"),
	preload("res://PowerUps/SpeedPowerUp.tscn"),
	preload("res://PowerUps/SizePowerUp.tscn"),
	preload("res://PowerUps/SpeedPowerUp.tscn"),
]


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
