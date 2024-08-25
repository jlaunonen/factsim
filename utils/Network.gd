class_name Network
extends Line2D

var connection_points: Array[Vector2] = []
var entities: Array = []  ## Asdf


class NetNode:
    var ent: int
    var conn: int

    func _init(_ent: int, _conn: int) -> void:
        self.ent = _ent
        self.conn = _conn

    func equals(other) -> bool:
        if other == null:
            return false
        if other is not NetNode:
            return false
        if other.ent != self.ent or other.conn != self.conn:
            return false
        return true

    func _to_string() -> String:
        return "({0}, {1})".format([self.ent, self.conn])


## Pack entity and connection id's (/NetNode) to a 64bit integer.
static func pack(ent: int, conn: int) -> int:
    assert(conn & 3 == conn)
    return ent | (conn << 60)


## Unpack an integer packed with [method Network.pack] as a NetNode tuple.
static func unpack(p: int) -> NetNode:
    # 0xFF..FF = 2^60 - 1
    # 3 = 2^2 - 1
    return NetNode.new(p & 0xFFFFFFFFFFFFFFF, (p >> 60) & 3)


## Create list of networks, and association from packed NetNode to network index.
static func reorder(entries: Array):
    # entries: [[se, sc, de, dc], ...]
    # result: [#se[sc]]

    var packed := []
    for pair in entries:
        var s : int = pack(pair[0], pair[1])
        var d : int = pack(pair[2], pair[3])
        packed.append([s, d])

    var networks := []
    var net_ids := {}
    while not packed.is_empty():
        var tbd: Array = packed.pop_front()
        var network := {}
        dig(packed, tbd[0], tbd[1], network)

        var r: Array[NetNode] = []
        for k in network.keys():
            assert(k not in net_ids)
            net_ids[k] = networks.size()
            r.append(unpack(k))
        print("Net ", networks.size(), ": ", r)
        networks.append(r)
    var fmtd = dict_format(net_ids, (func (k, v):
        return unpack(k).to_string() + ": " + str(v)
    ))
    prints("Net assoc:", fmtd)
    return [networks, net_ids]


static func dict_format(dict: Dictionary, entry_formatter: Callable) -> String:
    var r := []
    for key in dict:
        var value = dict[key]
        var fmt = entry_formatter.call(key, value)
        r.append(fmt)
    return "{" + ", ".join(r) + "}"


# TODO: Consider tail-optimizing?
static func dig(packed: Array, src: int, dst: int, network: Dictionary):
    var conn_pairs_to_source: Array = pluck_all(packed, src)
    var conn_pairs_to_dest: Array = pluck_all(packed, dst)
    # used as a Set
    network[src] = true
    network[dst] = true

    for pair in conn_pairs_to_source:
        dig(packed, pair[0], pair[1], network)
    for pair in conn_pairs_to_dest:
        dig(packed, pair[0], pair[1], network)


static func print_packed_net(net: Dictionary):
    var r: Array[NetNode] = []
    for k in net.keys():
        r.append(unpack(k))
    prints("Net:", r)


static func pluck_all(from: Array, id: int) -> Array:
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
