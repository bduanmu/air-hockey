class_name PowerUp extends Node


signal collected


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_body_entered(body):
	if body is Player:
		emit_signal("collected", body)


func on_collected(player: Player) -> void:
	print("collected")
	queue_free()
