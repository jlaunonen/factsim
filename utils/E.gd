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
