class_name PlayerInputSystem
extends System

const MOVE_SPEED: float = 6.0
const JUMP_SPEED: float = 4.0

var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func query() -> QueryBuilder:
	return q.with_all([C_PlayerControlled, C_Velocity, C_CharacterBodyRef])

func process(entity: Entity, delta: float) -> void:
	var velocity_comp: C_Velocity = entity.get_component(C_Velocity)
	var body_ref: C_CharacterBodyRef = entity.get_component(C_CharacterBodyRef)
	var character: CharacterBody3D = body_ref.node

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

	# Preserve vertical velocity
	input_vector.y = velocity_comp.velocity.y

	# Jump input
	if Input.is_action_just_pressed("jump") and character.is_on_floor():
		input_vector.y = JUMP_SPEED
	else:
		# Apply gravity if not jumping
		input_vector.y += -GRAVITY * delta

	velocity_comp.velocity = input_vector
