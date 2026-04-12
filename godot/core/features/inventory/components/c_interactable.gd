class_name C_Interactable extends Component
## Placed on items dropped in the world.

@export var item_name: String = "Item"
@export var action_verb: ActionVerb.ID = ActionVerb.ID.PICKUP
@export var item_id: int = 0

func _init(_name: String = "Item", _verb: ActionVerb.ID = ActionVerb.ID.PICKUP, _id: int = 0) -> void:
	item_name = _name
	action_verb = _verb
	item_id = _id
