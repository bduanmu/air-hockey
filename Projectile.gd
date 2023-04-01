class_name Projectile extends RigidBody2D


export (int) var speed: int = 500


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_body_entered")


func _on_body_entered(body: PhysicsBody2D) -> void:
	queue_free()
