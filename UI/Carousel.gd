class_name Carousel extends HBoxContainer


signal changed


export(Array, String) var states: Array
var current_state: int = 0 setget set_state


func _set_state(direction: int) -> void:
	current_state += direction
	current_state %= states.size()
	current_state += states.size()
	current_state %= states.size()
	$Label.text = states[current_state]
	emit_signal("changed", current_state)


func set_state(state: int) -> void:
	current_state = state
	$Label.text = states[current_state]
	emit_signal("changed", current_state)
