class_name CameraCollisionSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Camera, C_CameraCollision, C_CameraRigRef])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var col := entity.get_component(C_CameraCollision) as C_CameraCollision
		var rig := entity.get_component(C_CameraRigRef) as C_CameraRigRef

		if rig.spring == null:
			continue

		# Apply static config
		rig.spring.collision_mask = col.collision_mask
		rig.spring.margin = col.margin

		# Set desired base length; SpringArm3D handles collision shortening
		var desired := col.base_length

		col.effective_length = lerpf(col.effective_length, desired, clampf(col.recover_rate * delta, 0.0, 1.0))
		rig.spring.spring_length = col.effective_length
