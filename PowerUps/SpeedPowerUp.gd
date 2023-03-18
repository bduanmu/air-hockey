class_name SpeedPowerUp extends TimerPowerUp


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func use(player) -> void:
	.use(player)
	player.max_speed += 200
	player.accel_strength += 50


func on_timeout(player) -> void:
	if !is_instance_valid(player):
		queue_free()
		return
	player.max_speed -= 200
	player.accel_strength -= 50
