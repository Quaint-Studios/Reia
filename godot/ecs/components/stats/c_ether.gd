class_name C_Ether
extends Component

@export var current: float = 75.0
@export var maximum: float = 75.0

func _init(max_ether: float = 75.0):
	maximum = max_ether
	current = max_ether
