class_name WallPowerUp extends TimerPowerUp


signal spawn_wall


export(PackedScene) var wall_scene
export(int) var max_distance: int = 750


var wall


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func use(player, mouse_position: Vector2) -> void:
	.use(player, mouse_position)
	# Technically, the server should do this.
	mouse_position = player.position + (mouse_position - player.position).limit_length(max_distance)
	wall = wall_scene.instance()
	emit_signal("spawn_wall", wall, mouse_position)


func on_timeout(player) -> void:
	.on_timeout(player)
	if is_instance_valid(wall): 
		wall.queue_free()


func connect_signals(listener: Node) -> void:
	connect("spawn_wall", listener, "spawn_object")
