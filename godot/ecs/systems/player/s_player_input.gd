class_name PlayerInputSystem
extends System

const MOVE_SPEED: float = 6.0

func query() -> QueryBuilder:
	return q.with_all([C_PlayerControlled, C_Velocity])

func process(entity: Entity, _delta: float) -> void:
	var velocity_comp: C_Velocity = entity.get_component(C_Velocity)
	var input_vector: Vector3 = Vector3.ZERO

	# Keyboard input (WASD and arrow keys)
	if Input.is_action_pressed("move_forward"):
		input_vector.z -= 1.0
	if Input.is_action_pressed("move_back"):
		input_vector.z += 1.0
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1.0

	# Gamepad support (left stick)
	var axis_left_x: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var axis_left_z: float = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	input_vector.x += axis_left_x
	input_vector.z += axis_left_z

	# Normalize for consistent speed, discard if zero
	if input_vector != Vector3.ZERO:
		input_vector = input_vector.normalized() * MOVE_SPEED
	velocity_comp.velocity = input_vector
