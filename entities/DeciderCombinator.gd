extends CombinatorBase
class_name DeciderCombinator



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
	var con1: int = cfg.get("constant", 0)

	var op: String = cfg.get("comparator")

	var sig2 = cfg.get("second_signal", {})

	var out = cfg.get("output_signal", {})
	var out_from_in: bool = cfg.get("copy_count_from_input", false)

	var txt := "{0} {1} {2}\n⇒ {3} * {4}".format([
		get_operand(sig1, con1),
		op,
		get_operand(sig2, con1),
		parseSignalName(out),
		"IN" if out_from_in else "1",
	])

	label.text = txt
