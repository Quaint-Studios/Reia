class_name CameraRotationSystem
extends System

var aim_state: C_AimState = null

func query() -> QueryBuilder:
	return q.with_all([C_Camera, C_CameraOrbit, C_CameraRigRef])

static func _angle_lerp(current: float, target: float, rate: float, delta: float) -> float:
	var diff := wrapf(target - current, -PI, PI)
	return current + diff * clampf(rate * delta, 0.0, 1.0)

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var orbit := entity.get_component(C_CameraOrbit) as C_CameraOrbit
		var rig := entity.get_component(C_CameraRigRef) as C_CameraRigRef

		if rig.yaw == null or rig.pitch == null:
			continue

		# Smooth toward targets
		orbit.current_yaw = _angle_lerp(orbit.current_yaw, orbit.target_yaw, orbit.slerp_rate, delta)
		orbit.current_pitch = clampf(
			_angle_lerp(orbit.current_pitch, orbit.target_pitch, orbit.slerp_rate, delta),
			orbit.min_pitch, orbit.max_pitch
		)

		# Apply to rig
		rig.yaw.rotation.y = orbit.current_yaw
		rig.pitch.rotation.x = orbit.current_pitch

		if aim_state == null and not find_aim_state():
			return

		aim_state.yaw = orbit.current_yaw
		aim_state.pitch = orbit.current_pitch

func find_aim_state() -> bool:
	var entity: Entity = ECS.world.query.with_all([C_LocalPlayer, C_AimState]).execute_one()
	aim_state = entity.get_component(C_AimState) as C_AimState
	return aim_state != null
