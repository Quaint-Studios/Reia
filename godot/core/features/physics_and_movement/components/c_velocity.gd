class_name C_Velocity extends Component

@export var direction: Vector3 = Vector3.ZERO ## Represents the movement intent of an entity.
@export var speed: float = 0.0 ## Represents the movement speed of an entity

func _init(_direction: Vector3 = Vector3.ZERO, _speed: float = 0.0) -> void:
	direction = _direction
	speed = _speed
