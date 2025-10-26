class_name CameraModeBlendSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Camera, C_CameraMode]).with_any([C_AimState])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var mode := entity.get_component(C_CameraMode) as C_CameraMode
		var aiming := false
		if entity.has_component(C_AimState):
			aiming = (entity.get_component(C_AimState) as C_AimState).is_aiming

		var target_t := 1.0 if aiming else 0.0
		mode.blend_t = lerpf(mode.blend_t, target_t, clampf(mode.blend_rate * delta, 0.0, 1.0))

		mode.current_offset = mode.base_offset.lerp(mode.aim_offset, mode.blend_t)
		mode.current_fov = lerpf(mode.base_fov, mode.aim_fov, mode.blend_t)
