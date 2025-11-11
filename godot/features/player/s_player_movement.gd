class_name PlayerMovementSystem
extends System

const GRAVITY := 9.8

func query() -> QueryBuilder:
	return q.with_all([C_LocalPlayer, C_MoveInput, C_PlayerMovementConfig, C_PlayerJumpState, C_Transform]) \
	.iterate([C_MoveInput, C_PlayerMovementConfig, C_PlayerJumpState, C_Transform])

func process(entities: Array[Entity], components: Array[Array], delta: float) -> void:
	var camera_state: CameraStateData = LocalCache.camera_global.camera_state

	if camera_state == null:
		return

	var move: C_MoveInput = components[0][0]
	var cfg: C_PlayerMovementConfig = components[1][0]
	var jump_state: C_PlayerJumpState = components[2][0]
	var c_trs: C_Transform = components[3][0]

	var body := (entities[0] as Node) as CharacterBody3D

	# Build camera-relative move direction
	var dir := Vector3.ZERO
	if move.dir.length_squared() >= 0.000001:
		# Construct yaw-only basis from camera yaw
		var yaw_basis := Basis(Vector3.UP, deg_to_rad(camera_state.yaw))
		var forward := -yaw_basis.z
		var right := yaw_basis.x
		dir = ((right * move.dir.x) + (forward * move.dir.y)).normalized()

	var was_on_floor := body.is_on_floor()

	var base_speed := 0.0
	match move.state:
		C_MoveInput.MovementState.RUN:
			base_speed = cfg.run_speed
		C_MoveInput.MovementState.JOG:
			base_speed = cfg.jog_speed
		C_MoveInput.MovementState.WALK:
			base_speed = cfg.walk_speed
		C_MoveInput.MovementState.CROUCH:
			base_speed = cfg.walk_speed / 1.5
		C_MoveInput.MovementState.IDLE:
			base_speed = 0.0

	var control_multiplier := 1.0 if was_on_floor else cfg.air_control_multiplier
	var target_speed := base_speed * control_multiplier

	# Preserve vertical velocity; apply planar movement
	var vel := body.velocity
	vel.x = dir.x * target_speed
	vel.z = dir.z * target_speed

	# Handle jumping and gravity
	if was_on_floor:
		jump_state.coyote_timer = cfg.coyote_time
		jump_state.jumps_remaining = cfg.max_jumps
		jump_state.apex_hold_timer = 0.0
		jump_state.apex_hold_active = false
	else:
		jump_state.coyote_timer = max(jump_state.coyote_timer - delta, 0.0)

	var jump_pressed := move.jump_pressed
	move.jump_pressed = false
	if jump_pressed:
		if jump_state.jumps_remaining > 0 or was_on_floor or jump_state.coyote_timer > 0.0:
			jump_state.jump_buffer_timer = cfg.jump_buffer_time
		else:
			jump_state.jump_buffer_timer = 0.0

	var should_apply_gravity := true
	var can_ground_jump := was_on_floor or jump_state.coyote_timer > 0.0
	var has_jumps := jump_state.jumps_remaining > 0

	if jump_state.jump_buffer_timer > 0.0 and has_jumps and (can_ground_jump or not was_on_floor):
		# Perform jump
		vel.y = cfg.jump_speed
		jump_state.jump_buffer_timer = 0.0
		jump_state.coyote_timer = 0.0
		jump_state.apex_hold_timer = 0.0
		jump_state.apex_hold_active = false
		jump_state.jumps_remaining = max(jump_state.jumps_remaining - 1, 0)
		should_apply_gravity = false
	else:
		jump_state.jump_buffer_timer = max(jump_state.jump_buffer_timer - delta, 0.0)

	if should_apply_gravity:
		var gravity_scale := cfg.fall_multiplier if vel.y < 0.0 else 1.0
		vel.y -= GRAVITY * gravity_scale * delta

	body.velocity = vel
	var __ := body.move_and_slide()

	var is_on_floor_now := body.is_on_floor()
	jump_state.was_on_floor = is_on_floor_now
	if is_on_floor_now:
		jump_state.jumps_remaining = cfg.max_jumps
		jump_state.coyote_timer = cfg.coyote_time
		jump_state.apex_hold_timer = 0.0
		jump_state.apex_hold_active = false

	# Rotate body toward movement direction if there is input
	if dir.length() > 0.001:
		var current_yaw := body.rotation.y
		var target_yaw := atan2(dir.x, dir.z) # X/Z → yaw
		body.rotation.y = lerp_angle(current_yaw, target_yaw, clampf(cfg.turn_rate * delta, 0.0, 1.0))

	# Sync ECS transform from node
	c_trs.position = body.global_position
