class_name C_CurrentZone extends Component

## Tracks the deterministic Zone ID the entity is currently residing in.
@export var zone_id: int = 0

func _init(_zone_id: int = 0) -> void:
	zone_id = _zone_id
