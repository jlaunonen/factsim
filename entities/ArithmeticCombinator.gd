extends CombinatorBase
class_name ArithmeticCombinator



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
	var con1: int = cfg.get("first_constant", 0)

	var op: String = cfg.get("operation")

	var sig2 = cfg.get("second_signal", {})
	var con2: int = cfg.get("second_constant", 0)

	var out = cfg.get("output_signal", {})

	var txt := "{0} {1} {2}\n⇒ {3}".format([
		get_operand(sig1, con1),
		op,
		get_operand(sig2, con2),
		parseSignalName(out),
	])

	label.text = txt
