class_name C_Transform extends Component

## Represents the 3D position, rotation, and scale of an entity.
@export var transform: Transform3D = Transform3D.IDENTITY

func _init(_transform: Transform3D = Transform3D.IDENTITY) -> void:
	transform = _transform
