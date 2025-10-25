class_name AimAnimationSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_AimState]).iterate([C_AimState])

func process(entities: Array[Entity], components: Array[Array], _delta: float) -> void:
	var aims := components[0] as Array
	for i in range(entities.size()):
		var aim: C_AimState = aims[i]
		var entity := entities[i] as Entity
		# Use aim.yaw/pitch for animation pose
