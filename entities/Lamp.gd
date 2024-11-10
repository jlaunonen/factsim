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
var _circuit_enabled := false
var _valid_condition := false


func _ready() -> void:
	super()
	_ensure_color_map(colors)
	_apply_color(false, {})


func _apply_config() -> void:
	super()
	if _config == null:
		label.text = ""
		_valid_condition = false
		_circuit_enabled = false
		return
	_use_colors = _config.controlBehavior.get("use_colors", false)
	_circuit_enabled = _config.connection1 or _config.connection2

	var cfg = _config.controlBehavior.get("circuit_condition")
	if cfg == null:
		label.text = ""
		_valid_condition = false
		return

	var sig1 = cfg.get("first_signal", {})
	_const = cfg.get("constant", 0)

	_op = cfg.get("comparator")

	var sig2 = cfg.get("second_signal", {})

	_sig1 = parse_signal_key(sig1)
	_sig2 = parse_signal_key(sig2)

	_valid_condition = _sig1 and (_sig2 or cfg.has("constant"))

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
	if _circuit_enabled and _valid_condition and const_cond(_input_values):
		_apply_color(true, _input_values)
	elif not _circuit_enabled and _host.is_night:
		_apply_color(true, {})
	else:
		_apply_color(false, {})


func const_cond(signals: Dictionary) -> bool:
	var lhs : int
	var rhs : int
	# Only first can be ANYTHING / EVERYTHING.
	if self._sig1 == E.ANYTHING_SIGNAL or self._sig1 == E.EVERYTHING_SIGNAL:
		if self._sig2:
			rhs = signals.get(self.sig2, 0)
		else:
			rhs = self._const

		# When no signals, EVERYTHING gives true. ANYTHING gives false.
		if self._sig1 == E.ANYTHING_SIGNAL:
			var r := false
			for k in signals:
				var v : int = signals[k]
				if cond(v, rhs, self._op):
					r = true
			return r
		else:
			# EVERYTHING
			var r := true
			for k in signals:
				var v : int = signals[k]
				if not cond(v, rhs, self._op):
					r = false
			return r

	if self._sig1 and self._sig2:
		lhs = signals.get(self._sig1, 0)
		rhs = signals.get(self._sig2, 0)
	elif self._sig1:
		lhs = signals.get(self._sig1, 0)
		rhs = self._const
	elif self._sig2:
		lhs = self._const
		rhs = signals.get(self._sig2, 0)
	return cond(lhs, rhs, self._op)


static func cond(lhs: int, rhs: int, condition: String) -> bool:
	match condition:
		E.CMP_EQ: return lhs == rhs
		E.CMP_LT: return lhs < rhs
		E.CMP_GT: return lhs > rhs
		E.CMP_NE: return lhs != rhs
		E.CMP_LE: return lhs <= rhs
		E.CMP_GE: return lhs >= rhs
		_: return false
