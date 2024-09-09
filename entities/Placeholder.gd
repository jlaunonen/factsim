class_name Placeholder
extends CombinatorBase


func _apply_config() -> void:
	super()
	label.text = "? " + _config.name

	var has_1 = _config.connection1 != null
	c1_green.visible = has_1
	c1_red.visible = has_1

	var has_2 = _config.connection2 != null
	c2_green.visible = has_2
	c2_red.visible = has_2

	print(_config.to_string())
