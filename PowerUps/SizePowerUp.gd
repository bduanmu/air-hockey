class_name SizePowerUp extends PowerUp


onready var tween := Tween.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(tween)


func use(player) -> void:
	var shape: Shape2D = player.get_node("%CollisionShape2D").shape
	tween.interpolate_property(shape, "radius", shape.radius, shape.radius * 2, 0.2)
	tween.interpolate_property(player.get_node("%Sprite"), "scale", player.get_node("%Sprite").scale, player.get_node("%Sprite").scale * 2, 0.2)
	tween.start()
	# todo: Start timer to reverse the effects, prevent stacking
