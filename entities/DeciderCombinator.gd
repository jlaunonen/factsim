extends CombinatorBase
class_name DeciderCombinator


class Condition:
	var _sig1 := ""
	var _sig2 := ""
	var _const := 0
	var _op := ""

	func matches(lnet: Dictionary, rnet: Dictionary, outs: Dictionary) -> bool:
		var lhs : int
		var rhs : int

		# Only first can be special.
		if self._sig1 == E.ANYTHING_SIGNAL or self._sig1 == E.EVERYTHING_SIGNAL:
			if self._sig2:
				rhs = rnet.get(self._sig2, 0)
			else:
				rhs = self._const

			# When no signals, EVERYTHING gives true. ANYTHING gives false.
			if self._sig1 == E.ANYTHING_SIGNAL:
				var r := false
				for k in lnet:
					var v : int = lnet[k]
					if Lamp.cond(v, rhs, self._op):
						r = true
						outs[k] = v
				return r
			else:
				# EVERYTHING
				var r := true
				for k in lnet:
					var v : int = lnet[k]
					if not Lamp.cond(v, rhs, self._op):
						r = false
					elif outs.is_empty():
						outs[k] = v
				return r

		if self._sig1 == E.EACH_SIGNAL:
			# If the other one is also EACH
			if self._sig2 != E.EACH_SIGNAL:
				for k in lnet:
					var v : int = lnet[k]
					rhs = self.get_value(rnet, _sig2)
					if Lamp.cond(v, rhs, self._op):
						outs[k] = v
				return not outs.is_empty()

			else:
				assert(false, "Second signal may not be EACH.")

		if self._sig1 and self._sig2:
			lhs = lnet.get(self._sig1, 0)
			rhs = rnet.get(self._sig2, 0)
		elif self._sig1:
			lhs = lnet.get(self._sig1, 0)
			rhs = self._const
		elif self._sig2:
			lhs = self._const
			rhs = rnet.get(self._sig2, 0)

		return Lamp.cond(lhs, rhs, self._op)

	func get_value(net: Dictionary, sig: String) -> int:
		if sig:
			return net.get(sig, 0)
		return self._const


class Output:
	var _sig := ""
	var _copy_input := false


var _conditions: Condition
var _outputs: Output


func _apply_config() -> void:
	super()
	if _config == null:
		label.text = ""
		return
	var cfg = _config.controlBehavior.get("decider_conditions")
	if cfg == null:
		label.text = ""
		return

	var conds := ""
	if true:
		var cond = cfg
		var c = Condition.new()

		var sig1 = cond.get("first_signal", {})
		c._const = cond.get("constant", 0)

		c._op = cond.get("comparator", "<")

		var sig2 = cond.get("second_signal", {})

		c._sig1 = parse_signal_key(sig1)
		c._sig2 = parse_signal_key(sig2)

		_conditions = c

		conds += "{0} {1} {2}".format([
			get_operand(sig1, c._const),
			c._op,
			get_operand(sig2, c._const),
		])

	var outs := ""
	if true:
		var out = cfg
		var o = Output.new()
		var sig = out.get("output_signal", {})

		o._copy_input = out.get("copy_count_from_input", true)
		o._sig = parse_signal_key(sig)

		_outputs = o

		if not outs.is_empty():
			outs += "\n"
		outs += "⇒ {0} * {1}".format([
			parseSignalName(sig),
			"IN" if o._copy_input else "1",
		])

	if conds.is_empty() or outs.is_empty():
		label.text = conds + outs
	else:
		label.text = conds + "\n" + outs


func post_simulate() -> void:
	_clear_and_copy_from_1()


func _simulate() -> void:
	var result : bool
	var outs := {}
	result = _conditions.matches(_input_values, _input_values, outs)

	if result:
		for o in [_outputs]:
			var from : Dictionary = _input_values
			if o._sig == E.EVERYTHING_SIGNAL:
				var outputs := {}
				for k in from:
					var value : int = from[k] if o._copy_input else 1
					outputs[k] = from[k] if o._copy_input else 1
					_output_values[k] = value
				_send_all_to_net(E.NetConnectorGREEN_2, outputs)
				_send_all_to_net(E.NetConnectorRED_2, outputs)
			elif o._sig == E.EACH_SIGNAL:
				var outputs := {}
				for k in outs:
					var value : int = from[k] if o._copy_input else 1
					outputs[k] = value
					_output_values[k] = value
				_send_all_to_net(E.NetConnectorGREEN_2, outputs)
				_send_all_to_net(E.NetConnectorRED_2, outputs)
			else:
				var value : int = from.get(o._sig, 0) if o._copy_input else 1
				_send_to_net(E.NetConnectorGREEN_2, o._sig, value)
				_send_to_net(E.NetConnectorRED_2, o._sig, value)
				_output_values[o._sig] = value
	else:
		for o in _output_values:
			_output_values[o] = 0
