extends Line2D
class_name CombinatorBase

var colors: ColorDefs

@onready var label: Label = $"Label"
var animator: AnimationPlayer

var entity_id: int = -1
var c1_red: Node2D
var c1_green: Node2D

var c2_red: Node2D
var c2_green: Node2D

var _config: BpLoader.EntityDto

var _rotated: int = 0

var _connectors := [null, null, null, null]

var _networks := [null, null, null, null]

var _input_values := {}
var _output_values := {}
var _input_history : History

var _listeners := []
var _host: Node2D  ## SimulationHost


func _ready():
	animator = find_child("AnimationPlayer")
	c1_red = find_child("c1_red")
	c1_green = find_child("c1_green")
	c2_red = find_child("c2_red")
	c2_green = find_child("c2_green")

	_connectors[E.NetConnectorRED_1] = c1_red
	_connectors[E.NetConnectorRED_2] = c2_red
	_connectors[E.NetConnectorGREEN_1] = c1_green
	_connectors[E.NetConnectorGREEN_2] = c2_green

	var host = find_parent("SimulationHost")
	if host != null:
		_host = host
		_input_history = History.new(_host.backstack_depth)

	if colors == null:
		# Usually the shared colors instance is already set at this point, but if the node is present
		# in the main scene at start, they are not so try to read them from parent.
		if host != null:
			var host_colors = host.get("colors")
			if host_colors != null:
				colors = host_colors
		if colors == null:
			print("Warning: Colors not set for entity")
			colors = load("res://default.tres")

	_apply_config()


func get_rect() -> Rect2:
	if get_point_count() == 0:
		return Rect2(position, Vector2(0, 0))

	var r := Rect2(get_point_position(0), Vector2(0, 0))
	for i in range(1, get_point_count()):
		r = r.expand(get_point_position(i))

	return r


func get_conn_point(connector: int):
	var c: Sprite2D = _connectors[connector]
	if c != null:
		return c.get_global_transform() * Vector2.ZERO
	return null


func set_conn_highlight(connector: int, highlighted: bool) -> void:
	var c: Sprite2D = _connectors[connector]
	var netcolor: Color
	match E.enumToNetColor(connector):
		E.NetColorGREEN: netcolor = colors.green_highlight if highlighted else colors.green_normal
		E.NetColorRED: netcolor = colors.red_highlight if highlighted else colors.red_normal
		_: netcolor = Color.BLACK

	if c != null:
		c.modulate = netcolor


var _original_color
func set_entity_highlight(highlighted: bool) -> void:
	if _original_color == null:
		_original_color = default_color

	if highlighted:
		default_color = Color.WHITE
	else:
		default_color = _original_color


func move_with_connections(new_position: Vector2) -> void:
	position = new_position
	_move_all_net_segements()


func rotate_with_connections() -> void:
	if animator != null:
		_rotated = (_rotated + 1) % 4
		animator.seek(float(_rotated), true)
		_move_all_net_segements()


func _move_all_net_segements() -> void:
	_move_net_segments(E.NetConnectorRED_1)
	_move_net_segments(E.NetConnectorRED_2)
	_move_net_segments(E.NetConnectorGREEN_1)
	_move_net_segments(E.NetConnectorGREEN_2)


func _move_net_segments(conn: int) -> void:
	var net = _networks[conn]
	if net != null:
		var net_node = NetNode.pack_values(entity_id, conn)
		net.move_segments(net_node, get_conn_point(conn))


func set_config(cfg: BpLoader.EntityDto):
	_config = cfg
	entity_id = cfg.number
	_rotated = int(cfg.direction / 2.0)

	_fix_properties()

	if is_node_ready():
		_apply_config()


func _fix_properties() -> void:
	pass


func _apply_config() -> void:
	if animator != null:
		# poles don't have animator
		animator.current_animation = "orientation"
		animator.seek(float(_rotated), true)  # update=true, to be synchronous.


func _process(_delta):
	pass


static func parseSignalName(sig: Dictionary) -> String:
	if sig.is_empty():
		return ""
	var sigName : String = sig["name"]

	# Shorten special signal names.
	match sigName:
		"signal-anything": return "ANY"
		"signal-each": return "EACH"
		"signal-everything": return "EVR"

	return sigName.replace("signal-", "")


static func parse_signal_key(sig: Dictionary) -> String:
	if sig.is_empty():
		return ""
	return sig["type"] + ":" + sig["name"]


static func get_operand(sig, constant) -> String:
	if sig.is_empty():
		return str(constant)
	return parseSignalName(sig)


func set_network(conn: int, network: Network) -> void:
	_networks[conn] = network


func attach_listener(listener) -> void:
	_listeners.append(listener)
	listener.monitor(_input_values, _output_values)


func remove_listener(listener) -> void:
	_listeners.erase(listener)


signal configuration_changed()


## Read-phase of simulation
func post_simulate() -> void:
	pass


## Actual simulation / writes
func simulate() -> void:
	_output_values = {}
	_input_history.push_back(_input_values)

	_simulate()
	for l in _listeners:
		l.monitor(_input_values, _output_values)


func _simulate() -> void:
	pass


func apply_history(backtrack: int) -> void:
	_output_values = {}
	_input_values = _input_history.read_back(backtrack)

	_simulate()
	for l in _listeners:
		l.monitor(_input_values, _output_values)


func flush_history(backtrack: int) -> void:
	_input_history.drop_last(backtrack)


func _clear_and_copy_from_1() -> void:
	_input_values = {}

	_copy_from(E.NetConnectorGREEN_1)
	_copy_from(E.NetConnectorRED_1)


func _copy_from(conn: int) -> void:
	var net : Network = _networks[conn]
	if net != null:
		var values = net.values
		for k in values:
			var v = values[k]
			var org = _input_values.get_or_add(k, 0)
			_input_values[k] = org + v


func _send_to_net(conn: int, out_signal: String, value: int) -> void:
	var net: Network = _networks[conn]
	if net != null:
		net.add_value(out_signal, value)


func _send_all_to_net(conn: int, values: Dictionary) -> void:
	var net: Network = _networks[conn]
	if net != null:
		net.add_values(values)

# Component events

signal component_hover(entity)
signal component_blur(entity)
signal component_clicked(entity, event: InputEvent)


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		component_clicked.emit(self, event)


func _on_area_2d_mouse_entered() -> void:
	component_hover.emit(self)


func _on_area_2d_mouse_exited() -> void:
	component_blur.emit(self)
