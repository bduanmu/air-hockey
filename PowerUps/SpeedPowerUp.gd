class_name SpeedPowerUp extends TimerPowerUp


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func use(player) -> void:
	.use(player)
	player.speed += 2000


func on_timeout(player) -> void:
	if !is_instance_valid(player):
		queue_free()
		return
	player.speed -= 2000
