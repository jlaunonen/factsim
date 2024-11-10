extends CombinatorBase
class_name DeciderCombinator

const SPECIALS = [
	E.ANYTHING_SIGNAL,
	E.EACH_SIGNAL,
	E.EVERYTHING_SIGNAL,
]


var _sig1 := ""
var _sig2 := ""
var _const := 0
var _op := ""
var _out := ""
var _copy_input := false


func _apply_config() -> void:
	super()
	if _config == null:
		label.text = ""
		return
	var cfg = _config.controlBehavior.get("decider_conditions")
	if cfg == null:
		label.text = ""
		return

	var sig1 = cfg.get("first_signal", {})
	_const = cfg.get("constant", 0)

	_op = cfg.get("comparator")

	var sig2 = cfg.get("second_signal", {})

	var out = cfg.get("output_signal", {})
	_copy_input = cfg.get("copy_count_from_input", false)

	_sig1 = parse_signal_key(sig1)
	_sig2 = parse_signal_key(sig2)
	_out = parse_signal_key(out)

	var txt := "{0} {1} {2}\n⇒ {3} * {4}".format([
		get_operand(sig1, _const),
		_op,
		get_operand(sig2, _const),
		parseSignalName(out),
		"IN" if _copy_input else "1",
	])

	label.text = txt


func post_simulate() -> void:
	_clear_and_copy_from_1()


func _simulate() -> void:
	if _sig1 in SPECIALS or _sig2 in SPECIALS:
		# TODO
		pass
	elif Lamp.cond(_get_lhs(), _get_rhs(), _op):
		var value := 1
		if _copy_input:
			value = _input_values.get(_out, 0)
		_send_to_net(E.NetConnectorGREEN_2, _out, value)
		_send_to_net(E.NetConnectorRED_2, _out, value)
		_output_values[_out] = value
	else:
		_output_values[_out] = 0


func _get_lhs() -> int:
	if _sig1:
		return _input_values.get(_sig1, 0)
	return _const


func _get_rhs() -> int:
	if _sig2:
		return _input_values.get(_sig2, 0)
	return _const
