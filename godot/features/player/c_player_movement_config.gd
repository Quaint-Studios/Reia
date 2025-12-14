class_name C_PlayerMovementConfig
extends Component

@export var run_speed: float = 10.0
@export var jog_speed: float = 8.25 # walk_speed + (run_speed - walk_speed) / 2.0
@export var walk_speed: float = 6.5

@export var jump_speed: float = 7.5
@export var fall_multiplier: float = 1.75
@export var fast_fall_multiplier: float = 2.3
@export var fast_fall_trigger_speed: float = 6.0
@export var apex_hold_time: float = 0.08
@export var apex_snap_threshold: float = 1.2
@export var apex_drop_speed: float = 14.0
@export var air_control_multiplier: float = 0.65
@export var air_forward_accel: float = 8.0
@export var air_lateral_damp: float = 0.7
@export var air_idle_damp: float = 6.0
@export var max_jumps: int = 2
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export var turn_rate: float = 18.0 # how fast the character faces move direction
