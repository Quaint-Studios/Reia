class_name C_SpawnPoint extends Component

@export var prefab: PackedScene
@export var max_active: int = 5
@export var current_active: int = 0
@export var respawn_delay: float = 30.0
@export var timer: float = 0.0

func _init(_prefab: PackedScene = null, _max: int = 5, _delay: float = 30.0) -> void:
	prefab = _prefab
	max_active = _max
	respawn_delay = _delay
