class_name Selection
extends Node2D


@export_node_path
var hover_monitor = ^"../CanvasLayer/hoverMonitor"

@onready var _hover_monitor = get_node(hover_monitor)

const GRID_SIZE = 128  # todo: move somewhere and unify with main
const SNAP = Vector2(GRID_SIZE, GRID_SIZE)

var _selected_entity
var _current_detailed_entity
var _pressed := false


func _unhandled_input(event: InputEvent) -> void:
	# TODO: Consider input map
	if event is InputEventMouseButton:
		_mouse_press(event)

	elif event is InputEventMouseMotion:
		_mouse_motion(event)

	elif event is InputEventKey:
		_kb_press(event)


func _mouse_press(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_pressed = event.pressed

		if _current_detailed_entity != null:
			if _selected_entity != null:
				_selected_entity.set_entity_highlight(false)
			_selected_entity = _current_detailed_entity
			_selected_entity.set_entity_highlight(true)

		elif _selected_entity != null:
			_selected_entity.set_entity_highlight(false)
			_selected_entity = null

		get_viewport().set_input_as_handled()


func _mouse_motion(event: InputEventMouseMotion) -> void:
	if _pressed and _selected_entity != null:
		var pos_offset := Vector2(
			int(_selected_entity.position.x) % GRID_SIZE,
			int(_selected_entity.position.y) % GRID_SIZE,
		)
		var mouse_on_canvas: Vector2 = event.position * get_global_transform_with_canvas() - pos_offset
		var new_pos: Vector2 = snapped(mouse_on_canvas, SNAP) + pos_offset

		if not new_pos.is_equal_approx(_selected_entity.position):
			_selected_entity.move_with_connections(new_pos)


func _kb_press(event: InputEventKey) -> void:
	if event.pressed and not event.is_echo():
		if event.keycode == KEY_R and _selected_entity != null:
			_selected_entity.rotate_with_connections()


func on_entity_hover(entity) -> void:
	if _current_detailed_entity != null and _current_detailed_entity != entity:
		_current_detailed_entity.remove_listener(_hover_monitor)
	_current_detailed_entity = entity
	entity.attach_listener(_hover_monitor)
	_hover_monitor.set_component_id(entity.entity_id)


func on_entity_blur(entity) -> void:
	if _current_detailed_entity == entity:
		entity.remove_listener(_hover_monitor)
		_hover_monitor.clear()
		_current_detailed_entity = null
