class_name C_Transform
extends Component

@export var transform: Transform3D = Transform3D.IDENTITY
func _init(t: Transform3D = Transform3D.IDENTITY) -> void:
	transform = t
