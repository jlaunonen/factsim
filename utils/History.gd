class_name History
extends Object

# For later consideration, store array of PackedIntArrays?
var _history : Array[Dictionary] = []
var _depth : int = 0
var _write_pos : int = 0
var _real_size : int = 0

func _init(depth: int = 8) -> void:
	setup(depth)


## Setup history with memory depth.
## This will clear the history.
func setup(depth: int) -> void:
	_history.resize(depth)
	_history.fill({})
	_depth = depth
	_write_pos = 0
	_real_size = 0


## Push a new set of values to the history.
## Oldest entry might be removed.
func push_back(values: Dictionary) -> void:
	_history[_write_pos] = values
	_write_pos = (_write_pos + 1) % _depth
	_real_size = min(_real_size + 1, _depth)


## Count of values present in the history.
func size() -> int:
	return _real_size


## Read history from relative position [param pos].
## The `pos` should be a non-negative value and less than [method size()].
## `pos` = 0 is the latest entry, `pos` = 1 is the previous, ...
func read_back(pos: int) -> Dictionary:
	var index = (_write_pos - pos - 1 + _depth) % _depth
	return _history[index]


## Drop history entries until relative position [param pos].
## The `pos` should be a non-negative value and less than or equal to [method size()].
## With `pos` = 0, nothing is done. With `pos` = 1, the latest entry is removed,
## and writing continues after that.
func drop_last(pos: int) -> void:
	if pos <= 0:
		return
	pos = min(pos, _real_size)
	_write_pos = (_write_pos - pos + _depth) % _depth
	_real_size -= pos


static func run_test():
	var f = History.new()
	f.push_back({"p": 1})
	assert(f.size() == 1)
	assert(f.read_back(0)["p"] == 1)
	f.drop_last(1)
	assert(f.size() == 0)

	f.push_back({"p": 2})
	assert(f.read_back(0)["p"] == 2)

	f.setup(3)
	f.push_back({"p": 1})
	f.push_back({"p": 2})
	f.push_back({"p": 3}) # 1, 2, 3
	assert(f.read_back(0)["p"] == 3)
	assert(f.read_back(2)["p"] == 1)
	assert(f.read_back(3)["p"] == 3)

	f.push_back({"p": 4}) # 2, 3, 4
	assert(f.read_back(0)["p"] == 4)
	assert(f.read_back(2)["p"] == 2)
	assert(f.read_back(3)["p"] == 4)

	f.drop_last(1) # 2, 3
	assert(f.read_back(0)["p"] == 3)
	assert(f.read_back(1)["p"] == 2)
