extends CombinatorBase
class_name ConstantCombinator

@onready var btn: Button = $"Button"

var _enabled := false


func _ready():
	super()
	btn.pressed.connect(sw)
	_setBtnText(_enabled)


func sw():
	_setBtnText(not _enabled)


func _setBtnText(enabled: bool):
	_enabled = enabled
	if btn != null:
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
	for out in constOutputs:
		txt += parseSignalName(out["signal"]) + "=" + str(out["count"]) + "\n"

	label.text = txt

	_setBtnText(cfg.controlBehavior.get("enabled", false)) #TODO correct name?
