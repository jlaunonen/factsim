extends CombinatorBase
class_name Lamp

const COLOR_PRIORITY = [
	"red",
	"green",
	"blue",
	"yellow",
	"magenta",
	"cyan",
	"white",
	"gray",
	"black",
]

static var _signal_priority: Array[String]
static var _color_map: Dictionary

static func _ensure_color_map(_colors: ColorDefs):
	if _color_map == null or _color_map.is_empty():
		_color_map = {}
		_signal_priority = []
		for k in COLOR_PRIORITY:
			var v = _colors.get("sig_" + k)
			if v == null:
				v = Color.HOT_PINK

			var sig_name = "virtual:signal-" + k
			_color_map[sig_name] = v
			_signal_priority.append(sig_name)


@onready var indicator: Sprite2D = $"Circle"

var _use_colors := false
var _sig1 := ""
var _sig2 := ""
var _const := 0
var _op := ""


func _ready() -> void:
	super()
	_ensure_color_map(colors)
	_apply_color(false, {})


func _apply_config() -> void:
	super()
	if _config == null:
		label.text = ""
		return
	_use_colors = _config.controlBehavior.get("use_colors", false)

	var cfg = _config.controlBehavior.get("circuit_condition")
	if cfg == null:
		label.text = ""
		return

	var sig1 = cfg.get("first_signal", {})
	_const = cfg.get("constant", 0)

	_op = cfg.get("comparator")

	var sig2 = cfg.get("second_signal", {})

	_sig1 = parse_signal_key(sig1)
	_sig2 = parse_signal_key(sig2)

	var txt := "{0} {1} {2}".format([
		get_operand(sig1, _const),
		_op,
		get_operand(sig2, _const),
	])

	label.text = txt


func _apply_color(on: bool, signals: Dictionary):
	if not on:
		indicator.modulate = colors.lamp_off
		return
	if _use_colors:
		for s in _signal_priority:
			if signals.get(s, 0):
				indicator.modulate = _color_map[s]
				return
	indicator.modulate = colors.lamp_on


func post_simulate() -> void:
	_clear_and_copy_from_1()


func _simulate() -> void:
	if const_cond(_input_values, _sig1, _sig2, _const, _op):
		_apply_color(true, _input_values)
	else:
		_apply_color(false, {})


static func const_cond(signals: Dictionary, sig1: String, sig2: String, constant: int, condition) -> bool:
	var lhs : int
	var rhs : int
	if sig1 and sig2:
		lhs = signals.get(sig1, 0)
		rhs = signals.get(sig2, 0)
	elif sig1:
		lhs = signals.get(sig1, 0)
		rhs = constant
	elif sig2:
		lhs = constant
		rhs = signals.get(sig2, 0)

	match condition:
		"=": return lhs == rhs
		"<": return lhs < rhs
		">": return lhs > rhs
		"!=": return lhs != rhs
		"<=": return lhs <= rhs
		">=": return lhs >= rhs
		_: return false
