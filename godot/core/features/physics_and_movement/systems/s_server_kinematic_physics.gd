class_name ServerKinematicPhysicsSystem extends System

func query() -> QueryBuilder:
	return q.with_all([C_Transform, C_Velocity]).with_none([C_CharacterBody3D, C_Stunned, C_Dead])

func process(entities: Array[Entity], components: Array, delta: float) -> void:
	if not OS.has_feature("dedicated_server"): return

	var transforms: Array[C_Transform] = components[0]
	var velocities: Array[C_Velocity] = components[1]

	var count := entities.size()
	for i in range(count):
		var trans := transforms[i]
		var vel := velocities[i]

		# Pure vector math without touching the Godot Physics engine
		trans.transform.origin += vel.direction * vel.speed * delta
