class_name C_PlayerMovementConfig
extends Component

@export var run_speed: float = 10.0
@export var jog_speed: float = 8.25 # walk_speed + (run_speed - walk_speed) / 2.0
@export var walk_speed: float = 6.5

@export var jump_speed: float = 4.5
@export var fall_multiplier: float = 3.6
@export var air_control_multiplier: float = 0.55
@export var max_jumps: int = 2
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export var turn_rate: float = 18.0 # how fast the character faces move direction
