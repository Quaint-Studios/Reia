class_name C_MoveInput extends Component

## Stores the raw movement input intent from the client (e.g., joystick or WASD dir).
## The physics systems will read this to calculate the final C_Velocity.

@export var dir: Vector2 = Vector2.ZERO

func _init(_dir: Vector2 = Vector2.ZERO) -> void:
	dir = _dir
