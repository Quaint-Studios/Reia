class_name C_InventoryOpenRequest extends Component

## Attached when a player attempts to open an external inventory (like a Bank).
var target_inventory_entity: Entity

func _init(_target: Entity = null) -> void:
	target_inventory_entity = _target
