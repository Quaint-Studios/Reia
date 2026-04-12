class_name C_Interactable extends Component
## Placed on items dropped in the world.

@export var item_name: String = "Item"
@export var action_verb: ActionVerb.ID = ActionVerb.ID.PICKUP
@export var interact_op_code: OpCode.ID = OpCode.ID.PICKUP_ITEM

func _init(_name: String = "Item", _verb: ActionVerb.ID = ActionVerb.ID.PICKUP, _op: OpCode.ID = OpCode.ID.PICKUP_ITEM) -> void:
	item_name = _name
	action_verb = _verb
	interact_op_code = _op
