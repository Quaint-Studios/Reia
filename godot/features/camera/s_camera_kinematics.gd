class_name CameraKinematicsSystem
extends System

var follow_target: C_Transform = null

func _find_follow_target() -> C_Transform:
	if (follow_target == null):
		var result: Array[Entity] = ECS.world.query.with_all([C_LocalPlayer, C_Transform]).execute()
		follow_target = result[0].get_component(C_Transform) as C_Transform if not result.is_empty() else null

	return follow_target

func query() -> QueryBuilder:
	return q.with_all([C_Camera, C_CameraKinematics, C_CameraRigRef]).with_any([C_CameraMode])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var kin := entity.get_component(C_CameraKinematics) as C_CameraKinematics
		var rig := entity.get_component(C_CameraRigRef) as C_CameraRigRef
		var mode := entity.get_component(C_CameraMode) as C_CameraMode if entity.has_component(C_CameraMode) else null

		if rig.root == null:
			continue

		# Source follow point
		var source_pos := kin.target_position
		if source_pos == Vector3.ZERO:
			var follow_tr := _find_follow_target()
			if follow_tr != null:
				source_pos = follow_tr.position

		var target := source_pos + (mode.current_offset if mode else Vector3.ZERO)
		var pos := rig.root.global_position
		var vel := kin.current_velocity

		# Damp the spring
		var f := maxf(0.01, kin.frequency)
		var z := maxf(0.01, kin.damping_ratio)
		var g := 1.0 / (1.0 + 2.0 * z * f * delta + (f * f) * (delta * delta))
		var x := pos - target
		var temp := (vel + 2.0 * z * f * x) * delta
		var new_pos := (pos - temp + (f * f) * (delta * delta) * target) * g
		var new_vel := (vel + (target - new_pos) * (f * f) * delta) * g

		rig.root.global_position = new_pos
		kin.current_velocity = new_vel
		# Orientation handled in CameraRotationSystem
