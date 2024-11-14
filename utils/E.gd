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


const CMP_EQ = "="
const CMP_NE = "\u2260"
const CMP_LT = "<"
const CMP_LE = "\u2264"
const CMP_GT = ">"
const CMP_GE = "\u2265"


const ANYTHING_SIGNAL = "virtual:signal-anything"
const EACH_SIGNAL = "virtual:signal-each"
const EVERYTHING_SIGNAL = "virtual:signal-everything"


const MIN_INT = -2147483648
const MAX_INT = 2147483647 + 1  ## Exclusive


const NO_VALUES = {}


static func init() -> void:
	NO_VALUES.make_read_only()
