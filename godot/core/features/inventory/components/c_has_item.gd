class_name C_HasItem extends Component

## Relationship component tracking item quantities within an inventory.
@export var quantity: int = 1

func _init(_quantity: int = 1) -> void:
    quantity = _quantity
