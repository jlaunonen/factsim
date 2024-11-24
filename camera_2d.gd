extends Camera2D


var _is_dragging := false
var _drag_start: Vector2
var _start_offset: Vector2


func _input(event: InputEvent) -> void:
	if not enabled:
		# Don't process events from "other" layered scenes.
		return

	if event.is_action_pressed("rmb"):
		# Not really correct position, but as used for difference,
		# it behaves better than screen_transform.
		if not _is_dragging:
			var scene_pos: Vector2 = event.position / zoom.x
			_is_dragging = true
			_drag_start = scene_pos
			_start_offset = offset
			get_viewport().set_input_as_handled()
	elif event.is_action_released("rmb"):
		_is_dragging = false
		get_viewport().set_input_as_handled()
	elif _is_dragging and event is InputEventMouseMotion:
		var scene_pos: Vector2 = event.position / zoom.x
		var scene_diff: Vector2 = scene_pos - _drag_start
		offset = _start_offset - scene_diff
		get_viewport().set_input_as_handled()
