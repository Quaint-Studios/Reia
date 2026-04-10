class_name C_CurrentZone extends Component

## Tracks the deterministic Zone ID the entity is currently residing in.
@export var zone_id: Zone.ID = Zone.ID.WATERBROOK

func _init(_zone_id: Zone.ID = Zone.ID.WATERBROOK) -> void:
	zone_id = _zone_id
