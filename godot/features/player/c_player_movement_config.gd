class_name C_PlayerMovementConfig
extends Component

@export var run_speed: float = 10.0
@export var jog_speed: float = 8.25 # walk_speed + (run_speed - walk_speed) / 2.0
@export var walk_speed: float = 6.5

@export var jump_speed: float = 14.0
@export var max_jumps: int = 2
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.12

const TURN_RATE: float = 18.0 # how fast the character faces move direction
