class_name C_CameraMode
extends Component

enum CameraMode {NORMAL, AIMING}

@export var current_mode: int = CameraMode.NORMAL

@export var base_offset: Vector3 = Vector3(0.0, 2.0, 0.0)
@export var aim_offset: Vector3 = Vector3(0.8, 1.7, 0.0)

@export var base_fov: float = 75.0
@export var aim_fov: float = 60.0

@export var blend_rate: float = 8.0
@export var blend_t: float = 0.0 # 0 = base, 1 = aim

# Derived (write-only by system)
var current_offset: Vector3 = base_offset
var current_fov: float = base_fov
