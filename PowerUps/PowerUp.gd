class_name PowerUp extends Area2D


enum Type {
	SIZE, 
	SPEED,
	WALL,
	TEMP2,
	
	#COUNT is the amount of power ups
	COUNT,
}


signal collected


export(Type) var type: int
export(Texture) var indicator_texture: Texture
export(Texture) var powerup_texture: Texture

var is_valid: bool
var index: int


func _ready():
	var sprite := Sprite.new()
	sprite.texture = powerup_texture
	sprite.scale = Vector2(1, 1) * ($CollisionShape2D.shape.radius * 2) / 256
	add_child(sprite)


func _on_body_entered(body):
	emit_signal("collected", body)


func on_collected() -> void:
	hide()
	set_deferred("monitoring",  false)
	set_deferred("monitorable", false)
	is_valid = true


func use(player, mouse_position: Vector2) -> void:
	queue_free()


func update_indicator(player) -> void:
	pass


func connect_signals(listener: Node) -> void:
	pass
