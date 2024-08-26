class_name Network
extends Line2D

var connection_points: Array[Vector2] = []
var entities: Array = []  ## Array[CombinatorBase]


## Create list of networks, and association from packed NetNode to network index.
static func reorder(entries: Array):
	# entries: [[se, sc, de, dc], ...]

	var packed := []
	for pair in entries:
		var s : int = NetNode.pack_values(pair[0], pair[1])
		var d : int = NetNode.pack_values(pair[2], pair[3])
		packed.append([s, d])

	var networks := []  ## Array[Array[NetNode]]
	var net_ids := {}  ## Dictionary[int, int]  # packed key of NetNode
	while not packed.is_empty():
		var tbd: Array = packed.pop_front()
		var network := {}
		_dig(packed, tbd[0], tbd[1], network)

		var r: Array[NetNode] = []
		for k in network.keys():
			assert(k not in net_ids)
			# net_ids[NetNode.unpack(k)] might be nicer, but unusable due Dictionary
			# key behavior being interesting.
			net_ids[k] = networks.size()
			r.append(NetNode.unpack(k))

		print("Net ", networks.size(), ": ", r)
		networks.append(r)

	var fmtd = dict_format(net_ids, NetNode.unpack, str)
	prints("Net assoc:", fmtd)
	return [networks, net_ids]


static func dict_format(dict: Dictionary, key_formatter: Callable, value_formatter: Callable) -> String:
	var r := []
	for key in dict:
		var value = dict[key]
		var key_fmt = key_formatter.call(key)
		var value_fmt = value_formatter.call(value)
		r.append(str(key_fmt) + ": " + str(value_fmt))
	return "{" + ", ".join(r) + "}"


# TODO: Consider tail-optimizing?
static func _dig(packed: Array, src: int, dst: int, network: Dictionary):
	var conn_pairs_to_source: Array = _pluck_all(packed, src)
	var conn_pairs_to_dest: Array = _pluck_all(packed, dst)
	# used as a Set
	network[src] = true
	network[dst] = true

	for pair in conn_pairs_to_source:
		_dig(packed, pair[0], pair[1], network)
	for pair in conn_pairs_to_dest:
		_dig(packed, pair[0], pair[1], network)


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
