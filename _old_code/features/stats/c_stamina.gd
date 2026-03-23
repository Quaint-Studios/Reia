class_name C_Stamina
extends Component

@export var current: float = 100.0
@export var maximum: float = 100.0

func _init(max_ether: float = 100.0) -> void:
	maximum = max_ether
	current = max_ether
