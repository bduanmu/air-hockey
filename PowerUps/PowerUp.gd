class_name PowerUp extends Area2D


enum Type {
	SIZE, 
	SPEED,
	
	#COUNT is the amount of power ups
	COUNT,
}


signal collected


export(Type) var type: int

var is_valid: bool
var index: int


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
