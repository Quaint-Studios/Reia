class_name C_InventoryActionBlocked extends Component

## Appended by validator systems to veto an action.
@export var error_code: int = 0

func _init(_error_code: int = 0) -> void:
	error_code = _error_code
