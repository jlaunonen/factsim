extends CombinatorBase


# To make poles monitorable.
# TODO: Find out if this could be done differently without copying the values to each pole.
func post_simulate() -> void:
	_clear_and_copy_from_1()
