extends CombinatorBase
class_name ArithmeticCombinator


var _sig1 := ""
var _sig2 := ""
var _const1 := 0
var _const2 := 0
var _op := ""
var _out := ""


func _apply_config() -> void:
	super()
	if _config == null:
		label.text = ""
		return
	var cfg = _config.controlBehavior.get("arithmetic_conditions")
	if cfg == null:
		label.text = ""
		return

	var sig1 = cfg.get("first_signal", {})
	_const1 = cfg.get("first_constant", 0)

	_op = cfg.get("operation")

	var sig2 = cfg.get("second_signal", {})
	_const2 = cfg.get("second_constant", 0)

	var out = cfg.get("output_signal", {})

	_sig1 = parse_signal_key(sig1)
	_sig2 = parse_signal_key(sig2)
	_out = parse_signal_key(out)

	var txt := "{0} {1} {2}\n⇒ {3}".format([
		get_operand(sig1, _const1),
		_op,
		get_operand(sig2, _const2),
		parseSignalName(out),
	])

	label.text = txt


func post_simulate() -> void:
	_clear_and_copy_from_1()


func _simulate() -> void:
	if _out == E.EACH_SIGNAL:
		# Pairwise operations with a value.
		var values: Dictionary
		if _sig1 == E.EACH_SIGNAL:
			# EACH [] const/sig -> EACH
			values = each(_input_values, _get_rhs(), _op)
		else:
			# At least one EACH input must be present for EACH to be valid output.
			values = {}

		_send_all_to_net(E.NetConnectorGREEN_2, values)
		_send_all_to_net(E.NetConnectorRED_2, values)
		_output_values = values
	else:
		# Single output.
		var value: int
		if _sig1 == E.EACH_SIGNAL:
			# EACH [] const/sig -> sig : sum of results
			value = each_sum(_input_values, _get_rhs(), _op)
		else:
			# const/sig [] const/sig -> sig
			value = oper(_get_lhs(), _get_rhs(), _op)

		_send_to_net(E.NetConnectorGREEN_2, _out, value)
		_send_to_net(E.NetConnectorRED_2, _out, value)
		_output_values[_out] = value


func _get_lhs() -> int:
	if _sig1:
		return _input_values.get(_sig1, 0)
	return _const1


func _get_rhs() -> int:
	if _sig2:
		return _input_values.get(_sig2, 0)
	return _const2


static func oper(lhs: int, rhs: int, operation: String) -> int:
	match operation:
		"+": return wrapi(lhs + rhs, E.MIN_INT, E.MAX_INT)
		"-": return wrapi(lhs - rhs, E.MIN_INT, E.MAX_INT)
		"*": return wrapi(lhs * rhs, E.MIN_INT, E.MAX_INT)
		"/":
			if rhs == 0:
				return 0
			return wrapi(lhs / rhs, E.MIN_INT, E.MAX_INT)
		"%":
			if rhs == 0:
				return 0
			return wrapi(lhs % rhs, E.MIN_INT, E.MAX_INT)
		"^": return wrapi(lhs ** rhs, E.MIN_INT, E.MAX_INT)
		"<<": return wrapi(lhs << rhs, E.MIN_INT, E.MAX_INT)
		">>": return lhs >> rhs
		"AND": return lhs & rhs
		"OR": return wrapi(lhs | rhs, E.MIN_INT, E.MAX_INT)
		"XOR": return wrapi(lhs ^ rhs, E.MIN_INT, E.MAX_INT)
		_: return 0


static func each(signals: Dictionary, constant: int, operation: String) -> Dictionary:
	var r := {}
	for k in signals:
		var v = signals.get(k, 0)
		if v != 0:
			r[k] = oper(v, constant, operation)
	return r


static func each_rev(signals: Dictionary, constant: int, operation: String) -> Dictionary:
	var r := {}
	for k in signals:
		var v = signals.get(k, 0)
		if v != 0:
			r[k] = oper(constant, v, operation)
	return r


static func each_sum(signals: Dictionary, constant: int, operation: String) -> int:
	var r := 0
	for k in signals:
		var v = signals.get(k, 0)
		if v != 0:
			r += oper(v, constant, operation)
	return r


static func each_sum_rev(signals: Dictionary, constant: int, operation: String) -> int:
	var r := 0
	for k in signals:
		var v = signals.get(k, 0)
		if v != 0:
			r += oper(constant, v, operation)
	return r
