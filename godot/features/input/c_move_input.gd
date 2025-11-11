class_name C_MoveInput
extends Component

# x: right (+1), left (-1)
# y: forward (+1), back (-1)
@export var dir: Vector2 = Vector2.ZERO

enum MovementState {
	IDLE,
	CROUCH,
	WALK,
	JOG,
	RUN
}
@export var state: MovementState = MovementState.IDLE

@export var jump_pressed: bool = false
