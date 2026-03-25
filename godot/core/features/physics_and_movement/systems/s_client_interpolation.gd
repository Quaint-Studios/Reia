class_name ClientInterpolationSystem extends System

func query() -> QueryBuilder:
	return q.with_all([C_Transform, C_MovementSync])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var sync := entity.get_component(C_MovementSync) as C_MovementSync
		var target_pos := sync.server_transform.origin
		
		if entity.has_component(C_LocalPlayer):
			# Rubberband correction if prediction fails heavily
			if (entity as Node as Node3D).global_transform.origin.distance_to(target_pos) > 2.0:
				(entity as Node as Node3D).global_transform.origin = target_pos
		else:
			# Smoothly interpolate other players/monsters visually
			(entity as Node as Node3D).global_transform.origin = (entity as Node as Node3D).global_transform.origin.lerp(target_pos, delta * 15.0)
