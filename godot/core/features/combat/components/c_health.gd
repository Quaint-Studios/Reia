class_name C_Health extends Component

@export var current: int = 100
@export var max_health: int = 100

func _init(_current: int = 100, _max: int = 100) -> void:
	current = _current
	max_health = _max
