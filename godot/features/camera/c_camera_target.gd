class_name C_CameraTarget
extends Component

enum Mode {
	FOLLOW,
	FREE,
	CINEMATIC
}

var target_entity: Entity = null
@export var mode: Mode = Mode.FOLLOW

# Camera orbit parameters
@export var offset: Vector3 = Vector3(0, 2, -6)
@export var look_point_offset: Vector3 = Vector3(0, 1.5, 0)
@export var smoothing: float = 0.15

# Orbit angles and distance (for third-person camera)
@export var yaw: float = 0.0 # Horizontal angle (radians)
@export var pitch: float = 0.2 # Vertical angle (radians, slightly above horizon)
@export var distance: float = 6.0 # Camera distance from target

# Zoom and pitch limits
@export var min_distance: float = 2.0
@export var max_distance: float = 12.0
@export var min_pitch: float = -0.4
@export var max_pitch: float = 1.2
