class_name PlayerInputSystem
extends System

const MOVE_SPEED: float = 6.0
const JUMP_SPEED: float = 4.0
const LATERAL_BLEND: float = 0.3 # 0.0 = no control, 1.0 = full control

var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func query() -> QueryBuilder:
	return q.with_all([C_PlayerControlled, C_Velocity, C_CharacterBodyRef, C_DashIntent])

func process(entity: Entity, delta: float) -> void:
	var velocity_comp: C_Velocity = entity.get_component(C_Velocity)
	var body_ref: C_CharacterBodyRef = entity.get_component(C_CharacterBodyRef)
	var dash_intent: C_DashIntent = entity.get_component(C_DashIntent)
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

	# Normalize horizontal movement for consistent speed
	var horizontal_input := Vector3(input_vector.x, 0.0, input_vector.z)
	if horizontal_input != Vector3.ZERO:
		horizontal_input = horizontal_input.normalized()

	# Set vertical velocity
	var vertical_velocity := velocity_comp.velocity.y
	if Input.is_action_just_pressed("jump") and character.is_on_floor():
		vertical_velocity = JUMP_SPEED
	else:
		vertical_velocity += -GRAVITY * delta

	# Dash input (e.g., Shift or gamepad button)
	if Input.is_action_just_pressed("dash") and dash_intent.cooldown <= 0.0:
		dash_intent.triggered = true
		dash_intent.direction = horizontal_input if horizontal_input.length() > 0.01 else -character.transform.basis.z

	# If dashing, blend dash velocity with lateral input and preserve vertical velocity
	if dash_intent.dash_time_left > 0.0:
		var dash_dir: Vector3 = dash_intent.direction.normalized()
		var lateral_dir: Vector3 = horizontal_input
		var blended_dir: Vector3 = (dash_dir * (1.0 - LATERAL_BLEND)) + (lateral_dir * LATERAL_BLEND)
		blended_dir = blended_dir.normalized() * DashAbilitySystem.DASH_SPEED
		blended_dir.y = vertical_velocity
		velocity_comp.velocity = blended_dir
	else:
		var final_velocity := horizontal_input * MOVE_SPEED
		final_velocity.y = vertical_velocity
		velocity_comp.velocity = final_velocity
