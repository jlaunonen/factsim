extends CombinatorBase
class_name ConstantCombinator

@onready var btn: Button = $"Button"

var _enabled := false
var _constants := {}


func _ready():
	super()
	_setBtnText(_enabled)


func _setBtnText(enabled: bool):
	_enabled = enabled
	if btn != null:
		btn.set_pressed_no_signal(enabled)
		btn.text = "ON" if enabled else "OFF"


func _fix_properties() -> void:
	# the component was created in wrong orientation, so these need to be offset by 2.
	_rotated = (_rotated + 2) % 4


func _apply_config() -> void:
	super()
	if _config == null:
		label.text = ""
		return

	var cfg = _config
	var constOutputs = cfg.controlBehavior.get("filters", [])
	var txt := ""
	_constants.clear()
	for out in constOutputs:
		txt += parseSignalName(out["signal"]) + "=" + str(out["count"]) + "\n"
		_constants[parse_signal_key(out["signal"])] = out["count"]

	label.text = txt

	_setBtnText(cfg.controlBehavior.get("is_on", true))


func _on_button_toggled(toggled_on: bool) -> void:
	_setBtnText(toggled_on)


func _simulate() -> void:
	if _enabled:
		_send_all_to_net(E.NetConnectorRED_1, _constants)
		_send_all_to_net(E.NetConnectorGREEN_1, _constants)
		_output_values = _constants
	else:
		_output_values = E.NO_VALUES
