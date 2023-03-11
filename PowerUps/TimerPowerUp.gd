class_name TimerPowerUp extends PowerUp


export(int) var duration: float = 5


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func use(player) -> void:
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = duration
	timer.connect("timeout", self, "on_timeout", [player])
	add_child(timer)


func on_timeout(player) -> void:
	queue_free()
