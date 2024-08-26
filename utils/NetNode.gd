class_name NetNode
extends Object

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


func pack() -> int:
	return pack_values(ent, conn)


## Pack entity and connection id's (/NetNode) to a 64bit integer.
static func pack_values(entity_id: int, connection_id: int) -> int:
	assert(connection_id & 3 == connection_id)
	return entity_id | (connection_id << 60)


## Unpack an integer packed with [method Network.pack_values] as a NetNode tuple.
static func unpack(p: int) -> NetNode:
	# 0xFF..FF = 2^60 - 1
	# 3 = 2^2 - 1
	return NetNode.new(p & 0xFFFFFFFFFFFFFFF, (p >> 60) & 3)

