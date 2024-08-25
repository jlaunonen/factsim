extends Line2D
class_name CombinatorBase

var colors: ColorDefs

@onready var label: Label = $"Label"
var animator: AnimationPlayer

var c1_red: Node2D
var c1_green: Node2D

var c2_red: Node2D
var c2_green: Node2D

var _config: BpLoader.EntityDto

var _rotated: int = 0

var _connectors := [null, null, null, null]

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


func set_config(cfg: BpLoader.EntityDto):
	_config = cfg
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
	return sigName.replace("signal-", "")


static func get_operand(sig, constant) -> String:
	if sig.is_empty():
		return str(constant)
	return parseSignalName(sig)
