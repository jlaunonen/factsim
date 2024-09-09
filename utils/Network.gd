class_name Network
extends Node2D

var net_id: int
#var connection_points: Array[Vector2] = []
var wires: Array  ## Array[(NetNode, NetNode)]
var entities: Dictionary = {} ## Dictionary[int, CombinatorBase]

var type : int  ## [enum E.NetColorRED] or [enum E.NetColorGREEN]

var values := {}  ## Current simulation values


func _init(_net_id: int, _wires: Array, _entities: Dictionary, _type: int) -> void:
	self.net_id = _net_id
	self.wires = _wires
	self.entities = _entities
	self.type = _type
	self.name = "Net-" + str(_net_id) + "-" + E.netColorToName(_type)


func _enter_tree() -> void:
	for wire in self.wires:
		var src_node: NetNode = wire[0]
		var dst_node: NetNode = wire[1]
		var src_ent = entities[src_node.ent]
		var dst_ent = entities[dst_node.ent]

		src_ent.set_network(src_node.conn, self)
		dst_ent.set_network(dst_node.conn, self)

		var src = src_ent.get_conn_point(src_node.conn)
		var dst = dst_ent.get_conn_point(dst_node.conn)

		prints(src, "--", dst)

		var line := Line2D.new()
		line.width = 2
		line.points = [src, dst]
		match type:
			E.NetColorRED: line.default_color = Color.RED
			E.NetColorGREEN: line.default_color = Color.GREEN

		add_child(line)
		line.owner = self


func add_values(values_to_add: Dictionary) -> void:
	for k in values_to_add:
		var value = values_to_add[k]
		var v : int = values.get_or_add(k, 0)
		values[k] = v + value


func add_value(signal_name: String, value: int) -> void:
	var v : int = values.get_or_add(signal_name, 0)
	values[signal_name] = v + value


func pre_simulate() -> void:
	for k in values:
		values[k] = 0


func dump_values() -> void:
	print(name, ": ", values)


## Create list of networks, and association from packed NetNode to network index.
static func reorder(entries: Array, _entities: Dictionary):
	# entries: [[se, sc, de, dc], ...]

	var packed := []
	for pair in entries:
		var s : int = NetNode.pack_values(pair[0], pair[1])
		var d : int = NetNode.pack_values(pair[2], pair[3])
		packed.append([s, d])

	var net_instances := []
	var networks := []  ## Array[Array[NetNode]]
	var net_ids := {}  ## Dictionary[int, int]  # packed key of NetNode
	while not packed.is_empty():
		var _net_id = networks.size()
		var network := {}
		var net_pairs := []
		_dig(packed, network, net_pairs)

		var r: Array[NetNode] = []
		for k in network.keys():
			assert(k not in net_ids)
			# net_ids[NetNode.unpack(k)] might be nicer, but unusable due Dictionary
			# key behavior being interesting.
			net_ids[k] = networks.size()
			r.append(NetNode.unpack(k))

		print("Net ", _net_id, ": ", r)
		print("-Wires: ", net_pairs)
		networks.append(r)

		var _type = E.enumToNetColor(r[0].conn)
		net_instances.append(Network.new(_net_id, net_pairs, _filter_entities(_entities, r), _type))

	var fmtd = dict_format(net_ids, NetNode.unpack, str)
	prints("Net assoc:", fmtd)
	return [networks, net_ids, net_instances]


static func dict_format(dict: Dictionary, key_formatter: Callable, value_formatter: Callable) -> String:
	var r := []
	for key in dict:
		var value = dict[key]
		var key_fmt = key_formatter.call(key)
		var value_fmt = value_formatter.call(value)
		r.append(str(key_fmt) + ": " + str(value_fmt))
	return "{" + ", ".join(r) + "}"


static func _dig(packed: Array, network: Dictionary, net_pairs: Array):
	var todo_list := [packed.pop_front()]
	var pos := 0
	while pos < todo_list.size():
		var src = todo_list[pos][0]
		var dst = todo_list[pos][1]

		var conn_pairs_to_source: Array = _pluck_all(packed, src)
		todo_list.append_array(conn_pairs_to_source)

		var conn_pairs_to_dest: Array = _pluck_all(packed, dst)
		todo_list.append_array(conn_pairs_to_dest)

		# used as a Set
		network[src] = true
		network[dst] = true

		net_pairs.append([NetNode.unpack(src), NetNode.unpack(dst)])

		pos += 1


static func _pluck_all(from: Array, id: int) -> Array:
	var r := []
	var p := 0
	while p < from.size():
		var el: Array = from[p]
		if el[0] == id or el[1] == id:
			r.append(el)
			from.remove_at(p)
		else:
			p += 1
	return r


static func _filter_entities(_entities: Dictionary, net: Array[NetNode]) -> Dictionary:
	var r := {}
	for node in net:
		var ent = _entities.get(node.ent)
		if ent != null && ent not in r:
			r[node.ent] = ent
	return r
