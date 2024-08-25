extends Object
class_name BpLoader

# https://wiki.factorio.com/Blueprint_string_format
class BlueprintDto:
	var label: String
	var description # String
	var entities: Array

	func _init(map: Dictionary = {}) -> void:
		self.label = map.get("label")
		self.description = map.get("description")

		var entArray = map.get("entities") as Array
		self.entities = entArray.map(EntityDto.new)

	func _to_string() -> String:
		var ents = self.entities.reduce((func (acc, el):
			var pre = (acc + ",\n  ") if acc else "\n  "
			return pre + el._to_string()), "")
		return "BlueprintDto(label={0}, entities=[{1}])".format([
			var_to_str(self.label), ents
		])


class EntityDto:
	var name: String
	var number: int
	var direction: int
	var position: Vector2
	var controlBehavior # Dictionary
	var connection1 # ConnectionPointDto
	var connection2 # ConnectionPointDto

	func _init(map: Dictionary = {}) -> void:
		self.name = map.get("name") as String
		self.number = map.get("entity_number")
		self.direction = map.get("direction", 0)
		self.position = BpLoader.positionToVector(map.get("position"))
		self.controlBehavior = map.get("control_behavior", {})
		var connections = map.get("connections", {})
		self.connection1 = ConnectionPointDto.newOrNull(connections.get("1", {}))
		self.connection2 = ConnectionPointDto.newOrNull(connections.get("2", {}))

	func _to_string() -> String:
		var cb = EntityDto.fmtOptional("controlBehavior", self.controlBehavior)
		var c1 = EntityDto.fmtOptional("connection1", self.connection1)
		var c2 = EntityDto.fmtOptional("connection2", self.connection2)
		return "EntityDto(#{6}, name={0}, direction={1}, position={2}{3}{4}{5})".format([
			var_to_str(self.name), self.direction, self.position, cb, c1, c2, self.number,
		])

	static func fmtOptional(n: String, value) -> String:
		if value:
			if value is Dictionary:
				return ", {0}={1}".format([n, JSON.stringify(value)])
			return ", {0}={1}".format([n, value.to_string()])
		return ""


class ConnectionPointDto:
	var red: Array # [ConnectiondataDto]
	var green: Array # [ConnectiondataDto]

	func _init(map: Dictionary = {}) -> void:
		self.red = map.get("red", []).map(ConnectionDataDto.new)
		self.green = map.get("green", []).map(ConnectionDataDto.new)

	func _to_string() -> String:
		return "{red=[{0}], green=[{1}]}".format([
			", ".join(self.red),
			", ".join(self.green),
		])

	static func newOrNull(map: Dictionary):
		if map.is_empty():
			return null
		return ConnectionPointDto.new(map)


class ConnectionDataDto:
	var entityId: int
	var connectorId: int

	func _init(map: Dictionary = {}) -> void:
		self.entityId = map.get("entity_id")
		# confusing naming. the id is ever 1 or 2, or null in which case it is the single one.
		self.connectorId = map.get("circuit_id", 1)

	func _to_string() -> String:
		if self.entityId and self.connectorId:
			return "(e#{0}, c#{1})".format([self.entityId, self.connectorId])
		return ""


static func positionToVector(map: Dictionary):
	return Vector2(map.get("x"), map.get("y"))


static func loadBp(bp: String):
	if bp.is_empty() or bp[0] != "0":
		print("Invalid or incompatible blueprint string")
		return null

	var compressed: PackedByteArray = Marshalls.base64_to_raw(bp.substr(1))
	return decodeBp(compressed)


static func openBp(bpFilename: String):
	var fileString: String = FileAccess.get_file_as_string(bpFilename)
	if fileString == null:
		print(FileAccess.get_open_error())
		return null

	fileString = fileString.strip_edges()
	if fileString.is_empty() or fileString[0] != "0":
		print("Invalid or incompatible blueprint string")
		return null

	var compressed: PackedByteArray = Marshalls.base64_to_raw(fileString.substr(1))
	return decodeBp(compressed)


static func decodeBp(fileBytes: PackedByteArray):
	var file: PackedByteArray = fileBytes.decompress_dynamic(1024*1024, FileAccess.COMPRESSION_DEFLATE)

	var fileJson: String = file.get_string_from_utf8()

	var bpData = JSON.parse_string(fileJson)

	return BlueprintDto.new(bpData.get("blueprint"))
