extends Button


func _ready() -> void:
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	$AnimationPlayer.play("Hover")


func _on_mouse_exited() -> void:
	$AnimationPlayer.play("RESET")
