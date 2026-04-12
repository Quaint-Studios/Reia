class_name ServerPhysicsSystem extends System

func query() -> QueryBuilder:
	# TODO: This assumes we use CharacterBody3D physics. Evaluate this for performance.
	return q.with_all([C_Transform, C_Velocity]).with_none([C_Stunned, C_Dead])

func process(entities: Array[Entity], components: Array, _delta: float) -> void:
	if not OS.has_feature("dedicated_server"): return

	# Extract the parallel component arrays directly based on query order
	var transforms: Array[C_Transform] = components[0]
	var velocities: Array[C_Velocity] = components[1]

	# Iterate by Index (Cache-friendly contiguous memory access)
	var count := entities.size()
	for i in range(count):
		var entity := entities[i]
		var trans := transforms[i] as C_Transform
		var vel := velocities[i] as C_Velocity

		# Fast direct access. No method calls, no hash lookups.
		var body := entity as Node as CharacterBody3D
		if body:
			body.velocity = vel.direction * vel.speed
			var _collided := body.move_and_slide()

			# Sync back
			trans.transform = body.global_transform
		else:
			# Mathematical fallback for non-physics entities
			trans.transform.origin += vel.direction * vel.speed * _delta
