extends Camera2D


var _is_dragging := false
var _drag_start: Vector2

func _unhandled_input(event: InputEvent):
	if event is InputEventMouse:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			pass
		elif event.button_mask & MOUSE_BUTTON_RIGHT:
			# Not really correct position, but as used for difference,
			# it behaves better than screen_transform.
			var scene_pos: Vector2 = event.position / zoom.x
			if not _is_dragging:
				_is_dragging = true
				_drag_start = scene_pos
				return

			var diff: Vector2 = scene_pos - _drag_start
			_drag_start = scene_pos
			offset = offset - diff
			get_viewport().set_input_as_handled()
		else:
			_is_dragging = false
			get_viewport().set_input_as_handled()
