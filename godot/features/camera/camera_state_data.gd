# Pure data Resource for camera values, easy to serialize or migrate to an ECS component later.
# Keep data-only: no behavior here.

class_name CameraStateData
extends Resource

@export var yaw: float = 0.0
@export var pitch: float = -10.0
@export var target_yaw: float = 0.0
@export var target_pitch: float = -10.0
@export var yaw_sensitivity: float = 0.1
@export var pitch_sensitivity: float = 0.1
@export var min_pitch: float = -45.0
@export var max_pitch: float = 45.0
@export var rotation_lerp_speed: float = 10.0

const ZOOM_STEP := 0.5
@export var distance: float = 6.5
@export var min_distance: float = 1.0
@export var max_distance: float = 7.0

@export var height_offset: float = 1.6
@export var offset: Vector3 = Vector3(0, 1.6, 0)

@export var fov: float = 70.0
@export var target_fov: float = 70.0
@export var fov_lerp_speed: float = 8.0

# smoothing / critically damped params
@export var follow_speed: float = 12.0
@export var rotation_speed: float = 12.0

# collision
@export var collision_margin: float = 0.1
@export var recover_rate: float = 5.0
@export var clipped_distance: float = 0.0 # runtime: effective collapsed distance
