class_name PlayerMovementSystem
extends System

const GRAVITY := 9.8

func query() -> QueryBuilder:
	return q.with_all([C_LocalPlayer, C_MoveInput, C_PlayerMovementConfig, C_Transform]) \
	.iterate([C_MoveInput, C_PlayerMovementConfig, C_Transform])

func process(entities: Array[Entity], components: Array[Array], delta: float) -> void:
	var camera_state: CameraStateData = LocalCache.camera_global.camera_state

	if camera_state == null:
		return

	var move: C_MoveInput = components[0][0]
	var cfg: C_PlayerMovementConfig = components[1][0]
	var c_trs: C_Transform = components[2][0]

	var body := (entities[0] as Node) as CharacterBody3D
	var dir: Vector3
	var speed: float

	# Build camera-relative move direction
	if move.dir.length() < 0.001:
		dir = Vector3.ZERO
	else:
		# Construct yaw-only basis from camera yaw
		var yaw_basis := Basis(Vector3.UP, deg_to_rad(camera_state.yaw))
		var forward := -yaw_basis.z
		var right := yaw_basis.x
		dir = ((right * move.dir.x) + (forward * move.dir.y)).normalized()
	speed = (cfg.run_speed if move.sprint else cfg.walk_speed)

	# Preserve vertical velocity; apply planar movement
	var vel := body.velocity
	vel.x = dir.x * speed
	vel.z = dir.z * speed

	# Handle jumping and gravity
	if body.is_on_floor():
		vel.y = 0.0

		if move.jump_pressed:
			vel.y = cfg.jump_speed
			move.jump_pressed = false # Consume jump input
	else:
		var gravity_scale := 1.0

		# Early jump release
		if vel.y > 0.0 and not move.jump_held:
			gravity_scale = cfg.jump_cut_multiplier
		elif vel.y < 0.0:
			gravity_scale = cfg.fall_multiplier

		vel.y -= GRAVITY * gravity_scale * delta

	body.velocity = vel
	var __ := body.move_and_slide()

	# Rotate body toward movement direction if there is input
	if dir.length() > 0.001:
		var current_yaw := body.rotation.y
		var target_yaw := atan2(dir.x, dir.z) # X/Z → yaw
		body.rotation.y = lerp_angle(current_yaw, target_yaw, clampf(cfg.turn_rate * delta, 0.0, 1.0))

	# Sync ECS transform from node
	c_trs.position = body.global_position
