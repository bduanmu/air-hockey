class_name Map extends Node2D


signal goal_scored


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_goal_scored(body: Node, side: int) -> void:
	emit_signal("goal_scored", side)
