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

@onready var indicator: Sprite2D = $"Circle"

var _use_colors := false


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
	var con1: int = cfg.get("constant", 0)

	var op: String = cfg.get("comparator")

	var sig2 = cfg.get("second_signal", {})

	var txt := "{0} {1} {2}".format([
		get_operand(sig1, con1),
		op,
		get_operand(sig2, con1),
	])

	label.text = txt
	_apply_color(false, ["yellow", "red"])  # TODO: the list of active signals should come from simulation


func _apply_color(on: bool, signals: Array[String]):
	if on and _use_colors:
		for s in COLOR_PRIORITY:
			if s in signals:
				indicator.modulate = _match_color(s)
				return
		indicator.modulate = Color.HOT_PINK
	else:
		indicator.modulate = colors.lamp_on if on else colors.lamp_off


func _match_color(signal_name: String) -> Color:
	match signal_name:
		"red": return colors.sig_red
		"green": return colors.sig_green
		"blue": return colors.sig_blue
		"yellow": return colors.sig_yellow
		"magenta": return colors.sig_magenta
		"cyan": return colors.sig_cyan
		"white": return colors.sig_white
		"gray": return colors.sig_gray
		"black": return colors.sig_black

	return Color.HOT_PINK


# TODO: Remove demo stuff
var _p := 0.0
var _c := ""
func _process(delta: float) -> void:
	_p += delta
	if _p > (1 + COLOR_PRIORITY.size()) * 2.0:
		_apply_color(false, [])
		_c = ""
		_p = 0.0
	elif _p > 2.0:
		var t = COLOR_PRIORITY[int((_p - 2.0) / 2.0)]
		if _c != t:
			_c = t
			_apply_color(true, [t])
