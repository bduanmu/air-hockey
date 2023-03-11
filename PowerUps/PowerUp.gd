class_name PowerUp extends Area2D


signal collected

var is_valid: bool


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_body_entered(body):
	emit_signal("collected", body)


func on_collected() -> void:
	hide()
	set_deferred("monitoring",  false)
	set_deferred("monitorable", false)
	is_valid = true


func use(player) -> void:
	queue_free()
