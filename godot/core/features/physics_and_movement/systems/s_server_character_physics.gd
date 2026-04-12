class_name ServerCharacterPhysicsSystem extends System

func query() -> QueryBuilder:
	return q.with_all([C_Transform, C_Velocity, C_CharacterBody3D]).with_none([C_Stunned, C_Dead])

func process(entities: Array[Entity], components: Array, _delta: float) -> void:
	if not OS.has_feature("dedicated_server"): return

	var transforms: Array[C_Transform] = components[0]
	var velocities: Array[C_Velocity] = components[1]

	var count := entities.size()
	for i in range(count):
		var entity := entities[i]
		var trans := transforms[i]
		var vel := velocities[i]

		var body := entity as Node as CharacterBody3D
		body.velocity = vel.direction * vel.speed
		var _collided := body.move_and_slide()

		trans.transform = body.global_transform
