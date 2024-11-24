extends Node2D

const Main = preload("res://main.tscn")

@export var switch_delay : float = 0.5
@export_file("*.json") var tests : Array[String]

@onready var test_node : Node2D = $"testNode"
@onready var test_result_tree : Tree = $"CanvasLayer/Tree"

var tests_config : Array[Dictionary] = []
var index := 0
var current_scene = null
var current_visible_index = -1

@onready var tree_root : TreeItem = test_result_tree.create_item()

var current_test_tree_item : TreeItem
var total_results := [0, 0]

func _ready() -> void:
	tree_root.set_text(0, "Tests")
	if tests.is_empty():
		var dir := DirAccess.open("res://tests")
		if dir:
			for f in dir.get_files():
				if f.ends_with(".json"):
					tests.append("res://tests/" + f)

	for test in tests:
		var base_name = test.get_file()
		var node_name = base_name.validate_node_name()
		tests_config.append({
			"res": test,
			"base_name": base_name,
			"node_name": node_name,
		})

	if tests:
		next.call_deferred(index)


func next(ind: int) -> void:
	if ind >= tests_config.size():
		tree_root.set_text(1, "{0} / {1}".format(total_results))
		return

	set_sim_visibility(-1, false)

	var cfg = tests_config[ind]
	print(" ** TEST ", cfg["node_name"])

	index = ind
	var test_data = load(cfg["res"])

	var new_scene = Main.instantiate()
	new_scene.load_initial_bp = false
	# Navigation causes odd error message after few scenes has been instantiated,
	# so disable it for now.
	new_scene.get_node(^"NavigationRegion2D").enabled = false

	var new_root := Node2D.new()
	new_root.name = cfg["node_name"]
	new_root.editor_description = cfg["res"]
	new_root.add_child(new_scene)
	test_node.add_child(new_root)

	current_test_tree_item = test_result_tree.create_item(tree_root)
	current_test_tree_item.set_text(0, cfg["base_name"])
	current_test_tree_item.set_metadata(0, cfg["node_name"])

	new_scene._load_bp(test_data)
	current_scene = new_scene

	run_tests.call_deferred()


func set_sim_visibility(ind: int, vis: bool) -> void:
	if (ind >= 0 and ind >= test_node.get_child_count()) or (ind < 0 and -ind - 1 >= test_node.get_child_count()):
		return
	var last_test = test_node.get_child(ind)
	if last_test:
		var root = (last_test as Node2D)
		root.visible = vis
		root.get_node(^"SimulationHost/CanvasLayer").visible = vis
		root.get_node(^"SimulationHost/Camera2D").enabled = vis
		root.get_node(^"SimulationHost").set_process(vis)


func run_tests() -> void:
	(current_scene.get_node(^"CanvasLayer/dayNight") as Button).button_pressed = true  # TODO: Check both

	for i in 5:
		current_scene.simulate()

	var result = check_asserts(true)
	current_test_tree_item.set_text(1, "{0} / {1}".format(result))
	if result[0] == result[1]:
		current_test_tree_item.collapsed = true
	total_results[0] += result[0]
	total_results[1] += result[1]

	await get_tree().create_timer(switch_delay).timeout
	next.call_deferred(index + 1)


func check_asserts(is_night: bool) -> Array[int]:
	var components = current_scene.get_node("components")
	var lamps = components.find_children("Lamp-*", "", false, false)
	var r : Array[int] = [0, lamps.size()]
	var node_name: String = current_test_tree_item.get_metadata(0)

	for l in lamps:
		var lamp := l as Lamp
		var defaults := {
			"expect_on": true,
			"expect_night": false,
		}
		var assert_extras = defaults.merged(lamp._config._src.get("_assert", {}), true)

		var succ: bool
		if assert_extras["expect_night"]:
			succ = lamp.is_on == is_night
		else:
			succ = lamp.is_on == assert_extras["expect_on"]

		var assertion = test_result_tree.create_item(current_test_tree_item)
		assertion.set_text(0, "{2}: {0}x{1}".format([l.position.x, l.position.y, l._config.number]))
		assertion.set_text(1, "PASS" if succ else "FAIL")
		assertion.set_metadata(0, node_name)
		if succ:
			r[0] += 1
	return r


func _on_tree_cell_selected() -> void:
	var s = test_result_tree.get_selected()
	if s != null:
		var item := s as TreeItem
		var node_name = item.get_metadata(0)
		if node_name == null:
			return
		var test_root = test_node.get_node(node_name)
		if test_root != null:
			var new_test = test_root.get_index()
			if new_test != current_visible_index:
				set_sim_visibility(current_visible_index, false)
				current_visible_index = new_test
				set_sim_visibility(new_test, true)
