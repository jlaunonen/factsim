# Factorio circuit network simulator
# Copyright (C) 2024  Jyrki Launonen

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

extends Node2D

const GRID_SIZE = 128
const GRID_OFFSET = Vector2(64, 64)

var _entityScenes = {
	"arithmetic-combinator": preload("res://entities/ArithmeticCombinator.tscn"),
	"constant-combinator": preload("res://entities/ConstantCombinator.tscn"),
	"decider-combinator": preload("res://entities/DeciderCombinator.tscn"),
	"small-lamp": preload("res://entities/Lamp.tscn"),
	"small-electric-pole": preload("res://entities/SmallPole.tscn"),
	"medium-electric-pole": preload("res://entities/MediumPole.tscn"),
	"big-electric-pole": preload("res://entities/BigPole.tscn"),
	"substation": preload("res://entities/Substation.tscn"),
}
var _fallbackScene = preload("res://entities/Placeholder.tscn")

## Shared color definitions (read by [method CombinatorBase._ready]).
@export var colors: ColorDefs

@onready var doLoad: Button = $"CanvasLayer/loadBluePrint"
@onready var bpString: TextEdit = $"CanvasLayer/TextEdit"
@onready var netVisualization: OptionButton = $"CanvasLayer/netOptions"
@onready var camera: Camera2D = $"Camera2D"
@onready var timer: Timer = $"Timer"
@onready var ups_label: Label = $"CanvasLayer/upsLabel"

@onready var components: Node2D = $"components"
@onready var connections: Node2D = $"connections"
@onready var routes: Node2D = $"routes"
@onready var simulated_steps: Label = $"CanvasLayer/simulatedSteps"
@onready var simulation_speed_label: Label = $"CanvasLayer/simSpeedLabel"
@onready var selection_manager = $"Selection"


var _simulated_steps := 0
var _is_auto_stepping := false
var _simulations_per_time := 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if colors == null:
		colors = load("res://default.tres")

	timer.timeout.connect(_on_timer_timeout)

	_load_bp(preload("res://initial.json"))
	_on_sim_speed_slider_value_changed($"CanvasLayer/simSpeedSlider".value)


func _on_timer_timeout() -> void:
	simulate()


func highlight_net(network: Array[NetNode], highlighted: bool) -> void:
	for net_node: NetNode in network:
		var ent = entities[net_node.ent]
		ent.set_conn_highlight(net_node.conn, highlighted)

var entities := {}
var netParts := []  # tuple[int, int, int, int]
var networks := []


func _on_load_blue_print_pressed() -> void:
	var bp: BpLoader.BlueprintDto = BpLoader.loadBpString(bpString.text)
	_load_bp(bp)


func _load_bp(bp):
	if bp == null:
		return
	if bp is JSON:
		bp = BpLoader.BlueprintDto.new(bp.data.get("blueprint"))
	if bp is Dictionary:
		bp = BpLoader.BlueprintDto.new(bp.get("blueprint"))
	print("Loaded v{0} data".format([bp.version_str()]))
	if bp.vmaj > 1:
		print("Cannot process too new data")
		return

	_simulated_steps = 0
	simulated_steps.text = str(0)

	removeAllChildren(components)
	removeAllChildren(connections)
	entities.clear()
	netParts.clear()
	networks.clear()

	var _bpArea = null
	for ent: BpLoader.EntityDto in bp.entities:
		var s = _entityScenes.get(ent.name, _fallbackScene)

		var n = s.instantiate()
		n.name += "-" + str(ent.number)
		n.colors = colors
		n.position = ent.position * GRID_SIZE
		n.set_config(ent)
		components.add_child(n)

		entities[ent.number] = n

		# BP's contain connections to both directions, thus this logic
		# will create logical duplicates. They are deduplicated later in reorder.
		if ent.connection1 != null:
			netParts.append_array(parseConnections(ent.number, E.NetConnectorRED_1, ent.connection1.red, E.NetColorRED))
			netParts.append_array(parseConnections(ent.number, E.NetConnectorGREEN_1, ent.connection1.green, E.NetColorGREEN))
		if ent.connection2 != null:
			netParts.append_array(parseConnections(ent.number, E.NetConnectorRED_2, ent.connection2.red, E.NetColorRED))
			netParts.append_array(parseConnections(ent.number, E.NetConnectorGREEN_2, ent.connection2.green, E.NetColorGREEN))

		var entityRect = n.transform * n.get_rect()
		if _bpArea != null:
			_bpArea = _bpArea.merge(entityRect)
		else:
			_bpArea = entityRect

		n.component_hover.connect(selection_manager.on_entity_hover)
		n.component_blur.connect(selection_manager.on_entity_blur)

	prints("Rawnet:", netParts)
	var netresult = Network.reorder(netParts, entities)
	networks = netresult[0]

	for net in netresult[2]:
		connections.add_child(net)
		net.owner = self

	camera.position = _bpArea.get_center()
	# also reset offset to be safe.
	_on_center_pressed()


func _on_net_options_item_selected(index: int) -> void:
	var v : int = netVisualization.get_item_id(index)
	var all := v == 2
	connections.visible = v == 0 or all
	routes.visible = v == 1 or all


static func removeAllChildren(parent: Node) -> void:
	for i in parent.get_child_count():
		var node = parent.get_child(-1)
		parent.remove_child(node)
		node.queue_free()


static func parseConnections(srcId: int, srcConnectorId: int, conns: Array, netColor: int) -> Array:
	var r := []
	for c: BpLoader.ConnectionDataDto in conns:
		r.append([srcId, srcConnectorId, c.entityId, E.connectorIdToEnum(c.connectorId, netColor)])
	return r


func _on_center_pressed() -> void:
	camera.offset = Vector2.ZERO


func simulate() -> void:
	_simulated_steps += 1
	_simulations_per_time += 1
	simulated_steps.text = str(_simulated_steps)

	# Zero out networks so new values can be written into them.
	for index in connections.get_child_count():
		var child = connections.get_child(index)
		child.pre_simulate()

	# Process entities; will directly output to networks.
	for index in components.get_child_count():
		var child = components.get_child(index)
		child.simulate()

	# Copy network values to buffers for next simulation.
	for index in components.get_child_count():
		var child = components.get_child(index)
		child.post_simulate()

	if timer.wait_time > 0.1 or not _is_auto_stepping:
		for index in connections.get_child_count():
			var child = connections.get_child(index)
			child.dump_values()


func _on_step_forward_pressed() -> void:
	simulate()


func _on_auto_step_toggled(toggled_on: bool) -> void:
	_is_auto_stepping = toggled_on
	if toggled_on:
		timer.start()
	else:
		timer.stop()


func _on_sim_speed_slider_value_changed(value: float) -> void:
	var new_timeout := 1.0 / value
	timer.wait_time = new_timeout
	if _is_auto_stepping and (value < 3 or timer.time_left > new_timeout):
		timer.stop()
		timer.start()
	simulation_speed_label.text = str(round(value * 10.0) / 10.0)


func _on_ups_timer_timeout() -> void:
	var sims = _simulations_per_time
	_simulations_per_time = 0

	ups_label.text = "{0} UPS / {1} FPS".format([sims, Performance.get_monitor(Performance.TIME_FPS)])
