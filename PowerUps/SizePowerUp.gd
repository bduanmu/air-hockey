class_name SizePowerUp extends TimerPowerUp


onready var tween := Tween.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(tween)


func use(player, mouse_position: Vector2) -> void:
	.use(player, mouse_position)
	var shape: Shape2D = player.get_node("%CollisionShape2D").shape
	tween.interpolate_property(shape, "radius", shape.radius, shape.radius * 2, 0.2)
	tween.interpolate_property(player.get_node("%Sprite"), "scale", player.get_node("%Sprite").scale, player.get_node("%Sprite").scale * 2, 0.2)
	tween.start()


func on_timeout(player) -> void:
	if !is_instance_valid(player):
		queue_free()
		return
	var shape: Shape2D = player.get_node("%CollisionShape2D").shape
	tween.interpolate_property(shape, "radius", shape.radius, shape.radius / 2, 0.2)
	tween.interpolate_property(player.get_node("%Sprite"), "scale", player.get_node("%Sprite").scale, player.get_node("%Sprite").scale / 2, 0.2)
	tween.start()
	tween.connect("tween_all_completed", self, "queue_free")
