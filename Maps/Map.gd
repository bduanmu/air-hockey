class_name Map extends Node2D


signal goal_scored

var powerups: Array
var powerup_locations: Array


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	powerup_locations = $"%PowerUpLocations".get_children()
	for i in range(powerup_locations.size()):
		powerups.append(null)


func _on_goal_scored(body: Node, side: int) -> void:
	emit_signal("goal_scored", side)


func spawn_powerup(powerup: PowerUp, id: int) -> void:
	powerup.position = powerup_locations[id].position
	add_child(powerup)
	powerups[id] = powerup


func on_powerup_collected(player: Player, id: int) -> void:
	player.powerup = powerups[id]
	powerups[id].on_collected()
	powerups[id] = null #todo: start the timer to spawn new powerups if applicable
