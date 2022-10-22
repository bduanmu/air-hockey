class_name HSliderWithLabel extends HBoxContainer


signal value_changed


var value: int = 100 setget set_value


func _ready() -> void:
	pass # Replace with function body.


func set_value(new_value: int) -> void:
	$CenterContainer/HSlider.value = new_value


func _on_hslider_value_changed(new_value: float) -> void:
	value = int(new_value)
	$Label.text = str(value)
	emit_signal("value_changed", value)
