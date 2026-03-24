class_name C_ItemTransferRequest extends Component

## Ephemeral component attached to an entity requesting to move an item between inventories.
var source_inventory: Entity
var target_inventory: Entity
@export var item_relationship: Relationship

func _init(_source: Entity = null, _target: Entity = null, _item: Relationship = null) -> void:
	source_inventory = _source
	target_inventory = _target
	item_relationship = _item
