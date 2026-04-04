class_name C_CastRequest extends Component

## An ephemeral component used to request a skill cast against a specific target.
## This is processed by the Combat/Validation execution systems.
@export var skill_id: int = 0
var target: Entity = null

func _init(_skill_id: int = 0, _target: Entity = null) -> void:
	skill_id = _skill_id
	target = _target
