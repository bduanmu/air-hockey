class_name Player extends KinematicBody2D


export (int, 0, 10000) var speed: int = 500


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	if (position - get_global_mouse_position()).length_squared() <= pow(speed / 60, 2):
		move_and_slide((get_global_mouse_position() - position) * 60)
	else:
		move_and_slide((get_global_mouse_position() - position).normalized() * speed)
	position = Vector2(int(position.x), int(position.y))
