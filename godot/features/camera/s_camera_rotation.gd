class_name CameraRotationSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Camera, C_CameraOrbit, C_CameraRigRef, C_AimState])

static func _angle_lerp(current: float, target: float, rate: float, delta: float) -> float:
	var diff := wrapf(target - current, -PI, PI)
	return current + diff * clampf(rate * delta, 0.0, 1.0)

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var orbit := entity.get_component(C_CameraOrbit) as C_CameraOrbit
		var rig := entity.get_component(C_CameraRigRef) as C_CameraRigRef

		# Ensure caches
		if rig.yaw == null or rig.pitch == null:
			continue

		# Smooth toward targets
		orbit.current_yaw = _angle_lerp(orbit.current_yaw, orbit.target_yaw, orbit.slerp_rate, delta)
		orbit.current_pitch = clampf(
			_angle_lerp(orbit.current_pitch, orbit.target_pitch, orbit.slerp_rate, delta),
			orbit.min_pitch, orbit.max_pitch
		)

		# Apply to rig if available
		if rig.yaw:
			rig.yaw.rotation.y = orbit.current_yaw
		if rig.pitch:
			rig.pitch.rotation.x = orbit.current_pitch

		# Optionally sync to C_AimState for consumers like animation
		if entity.has_component(C_AimState):
			var aim := entity.get_component(C_AimState) as C_AimState
			aim.yaw = orbit.current_yaw
			aim.pitch = orbit.current_pitch
