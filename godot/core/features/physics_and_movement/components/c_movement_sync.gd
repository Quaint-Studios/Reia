class_name C_MovementSync extends Component

## Holds the authoritative transform received from the server.
## Used by the ClientInterpolationSystem to smoothly lerp visual nodes.

@export var server_transform: Transform3D = Transform3D()

func _init(_server_transform: Transform3D = Transform3D()) -> void:
	server_transform = _server_transform
