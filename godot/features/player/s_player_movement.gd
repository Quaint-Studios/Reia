class_name PlayerMovementSystem
extends System

var orbit: C_CameraOrbit = null

func query() -> QueryBuilder:
	return q.with_all([C_LocalPlayer, C_MoveInput, C_PlayerMovementConfig, C_Transform]) \
	.iterate([C_MoveInput, C_PlayerMovementConfig, C_Transform])

func process(entities: Array[Entity], components: Array[Array], delta: float) -> void:
	if orbit == null:
		var q1 := ECS.world.query.with_all([C_Camera, C_CameraOrbit])
		var cams: Array[Entity] = q1.execute()
		if not cams.is_empty():
			var cam_entity := cams[0] as Entity
			orbit = cam_entity.get_component(C_CameraOrbit) as C_CameraOrbit

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
			var yaw_basis := Basis(Vector3.UP, orbit.current_yaw)
			var forward := -yaw_basis.z
			var right := yaw_basis.x
			dir = ((right * move.dir.x) + (forward * move.dir.y)).normalized()
		speed = (cfg.run_speed if move.sprint else cfg.walk_speed)

		# Preserve vertical velocity; apply planar movement
		var vel := body.velocity
		vel.x = dir.x * speed
		vel.z = dir.z * speed

		# Optional: simple gravity if you don’t have a separate gravity system
		# vel.y += ProjectSettings.get_setting("physics/3d/default_gravity") * delta

		body.velocity = vel
		var __ := body.move_and_slide()

		# Rotate body toward movement direction if there is input
		if dir.length() > 0.001:
			var current_yaw := body.rotation.y
			var target_yaw := atan2(dir.x, dir.z) # X/Z → yaw
			body.rotation.y = lerp_angle(current_yaw, target_yaw, clampf(cfg.turn_rate * delta, 0.0, 1.0))

		# Sync ECS transform from node
		c_trs.position = body.global_position
