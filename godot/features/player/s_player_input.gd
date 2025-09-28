class_name PlayerInputSystem
extends System

const MOVE_SPEED: float = 6.0
const JUMP_SPEED: float = 8.0
const ROTATE_SPEED: float = 12.0
const LATERAL_BLEND: float = 0.3 # 0.0 = no control, 1.0 = full control
const COYOTE_TIME: float = 0.25 # Seconds of coyote time

var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func query() -> QueryBuilder:
	return q.with_all([C_PlayerControlled, C_Velocity, C_CharacterBodyRef, C_DashIntent, C_CameraTargetRef, C_CoyoteTime])

func process(entity: Entity, delta: float) -> void:
	var velocity_comp: C_Velocity = entity.get_component(C_Velocity)
	var body_ref: C_CharacterBodyRef = entity.get_component(C_CharacterBodyRef)
	var dash_intent: C_DashIntent = entity.get_component(C_DashIntent)
	var camera_target: C_CameraTarget = (entity.get_component(C_CameraTargetRef) as C_CameraTargetRef).camera_target
	var coyote_time: C_CoyoteTime = entity.get_component(C_CoyoteTime)
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
	var move_dir := horizontal_input.rotated(Vector3.UP, camera_target.yaw)

	# Set vertical velocity and coyote time
	var vertical_velocity := velocity_comp.velocity.y
	if character.is_on_floor():
		coyote_time.timer = COYOTE_TIME
		if Input.is_action_just_pressed("jump"):
			vertical_velocity = JUMP_SPEED
			coyote_time.timer = 0.0
		else:
			if vertical_velocity <= 0.0:
				vertical_velocity = 0.0
	else:
		coyote_time.timer = max(0.0, coyote_time.timer - delta)
		vertical_velocity += -GRAVITY * delta

	var can_jump := character.is_on_floor() or coyote_time.timer > 0.0
	if Input.is_action_just_pressed("jump") and can_jump:
		vertical_velocity = JUMP_SPEED
		coyote_time.timer = 0.0
	else:
		coyote_time.timer = max(0.0, coyote_time.timer - delta)
		vertical_velocity += -GRAVITY * delta

	# Rotate player to face movement direction
	if move_dir.length() > 0.01:
		var target_rot := atan2(move_dir.x, move_dir.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_rot, delta * ROTATE_SPEED)

	# Dash input (e.g., Shift or gamepad button)
	if Input.is_action_just_pressed("dash") and dash_intent.cooldown <= 0.0:
		dash_intent.triggered = true
		if move_dir.length() > 0.01:
			dash_intent.direction = horizontal_input.rotated(Vector3.UP, camera_target.yaw)
		else:
			dash_intent.direction = Vector3(0, 0, -1).rotated(Vector3.UP, camera_target.yaw)

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
