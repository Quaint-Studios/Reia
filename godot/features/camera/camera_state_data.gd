# Pure data Resource for camera values, easy to serialize or migrate to an ECS component later.
# Keep data-only: no behavior here.

class_name CameraStateData
extends Resource

# Rotation
@export var yaw: float = 0.0
@export var pitch: float = -10.0
@export var target_yaw: float = 0.0
@export var target_pitch: float = -10.0
@export var yaw_sensitivity: float = 0.15
@export var pitch_sensitivity: float = 0.15
@export var min_pitch: float = -70.0
@export var max_pitch: float = 50.0
@export var rotation_lerp_speed: float = 20.0

# Zoom
const ZOOM_STEP := 0.5
@export var target_distance: float = 6.5
@export var distance: float = 6.5
@export var min_distance: float = 1.0
@export var max_distance: float = 7.0

# Camera positioning
@export var position_smooth: float = 8.0
@export var offset: Vector3 = Vector3(0, 1.6, 0)

# Field of View
@export var fov: float = 70.0
@export var target_fov: float = 70.0
@export var fov_lerp_speed: float = 8.0

# Smoothing / Critically damped params
@export var follow_speed: float = 12.0
