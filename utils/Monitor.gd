extends Node2D

@onready var name_label : Label = $"PanelContainer/VBoxContainer/HBoxContainer/nameLabel"
@onready var text_in : TextEdit = $"PanelContainer/VBoxContainer/TextEdit"
@onready var text_out : TextEdit = $"PanelContainer/VBoxContainer/TextEdit2"

func _ready() -> void:
	pass


func set_component_id(component_id: int) -> void:
	name_label.text = str(component_id)


func monitor(inputs: Dictionary, outputs: Dictionary) -> void:
	var ins = _stringify(inputs)
	var outs = _stringify(outputs)

	text_in.text = ins
	text_out.text = outs


func _stringify(map: Dictionary) -> String:
	var r := ""
	for k in map:
		if r:
			r += "\n"
		var v = map.get(k)
		r += k + "=" + str(v)

	return r


func clear() -> void:
	text_in.text = ""
	text_out.text = ""
	name_label.text = ""
