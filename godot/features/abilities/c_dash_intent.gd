class_name C_DashIntent
extends Component

var triggered: bool = false
var direction: Vector3 = Vector3.ZERO
var cooldown: float = 0.0
var dash_time_left: float = 0.0

# Resets the dash intent after processing
func reset() -> void:
	print("Resetting dash intent")
	triggered = false
	direction = Vector3.ZERO
	dash_time_left = 0.0
