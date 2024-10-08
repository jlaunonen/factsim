extends Object
class_name E

enum {
	NetColorRED = 0,
	NetColorGREEN = 2,
}
enum {
	NetConnectorRED_1,
	NetConnectorRED_2,
	NetConnectorGREEN_1,
	NetConnectorGREEN_2,
}

static func connectorIdToEnum(connectorId: int, netColor: int) -> int:
	return connectorId - 1 + netColor

static func enumToNetColor(netConnector: int) -> int:
	return NetColorRED if netConnector < NetConnectorGREEN_1 else NetColorGREEN

static func netColorToName(netColor: int) -> String:
	# XXX: Comparison from color to connector, but as they are supposed to be compatible, the function works for connectors too.
	return "RED" if netColor < NetConnectorGREEN_1 else "GREEN"
