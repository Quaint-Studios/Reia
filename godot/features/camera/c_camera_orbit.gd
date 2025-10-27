class_name C_CameraOrbit
extends Component

@export var distance: float = 4.0
@export var min_zoom: float = 2.0
@export var max_zoom: float = 12.0

@export var zoom_step: float = 0.5

@export var target_yaw: float = 0.0 # radians, wrapped [-PI, PI]
@export var target_pitch: float = 0.2 # radians, clamped

@export var current_yaw: float = 0.0
@export var current_pitch: float = 0.2

@export var yaw_sensitivity: float = 0.012
@export var pitch_sensitivity: float = 0.010

@export var min_pitch: float = -0.4
@export var max_pitch: float = 1.5

@export var slerp_rate: float = 12.0 # higher = snappier
