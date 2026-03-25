class_name C_AnimState extends Component

## Tracks the current logical state (often synced to AnimationTree).
@export var current_state: String = "IDLE"

func _init(_state: String = "IDLE") -> void:
	current_state = _state
