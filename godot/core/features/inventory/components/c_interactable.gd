class_name C_Interactable extends Component
## Placed on items dropped in the world.

@export var item_name: String = "Item"
@export var action_verb: String = "Pickup" # TODO: Auto generate a registry and enum the verb, we can convert it to a string for the UI prompt. E.g. "Pickup", "Open", "Read", "Talk", etc.
@export var item_id: int = 0

func _init(_name: String = "Item", _verb: String = "Pickup", _id: int = 0) -> void:
	item_name = _name
	action_verb = _verb
	item_id = _id
