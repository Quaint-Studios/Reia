class_name C_DamageEvent extends Component

## An ephemeral component used to process damage math for one frame.
@export var amount: int = 0
@export var damage_type: String = "PHYSICAL" # e.g., PHYSICAL, FIRE, FROST

func _init(_amount: int = 0, _type: String = "PHYSICAL") -> void:
	amount = _amount
	damage_type = _type
