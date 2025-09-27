class_name C_Health
extends Component

@export var current: float = 150.0
@export var maximum: float = 150.0

func _init(max_health: float = 150.0) -> void:
	maximum = max_health
	current = max_health
