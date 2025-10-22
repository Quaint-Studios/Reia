class_name CameraSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_CameraTarget, C_CameraRef])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var camera_target: C_CameraTarget = entity.get_component(C_CameraTarget)
		var camera_ref: C_CameraRef = entity.get_component(C_CameraRef)
		var camera: Camera3D = camera_ref.node

		match camera_target.mode:
			C_CameraTarget.Mode.FOLLOW:
				if camera_target.target_entity:
					var target_body: C_CharacterBodyRef = camera_target.target_entity.get_component(C_CharacterBodyRef)
					if target_body and target_body.node:
						var look_at_pos: Vector3 = target_body.node.global_transform.origin + camera_target.look_point_offset

						# Orbit calculation using yaw/pitch/distance from ECS component
						var distance: float = camera_target.distance
						var yaw: float = camera_target.yaw
						var pitch: float = camera_target.pitch

						var offset: Vector3 = Vector3(
							distance * cos(-pitch) * sin(yaw),
							distance * sin(-pitch),
							distance * cos(-pitch) * cos(yaw)
						)

						var target_pos: Vector3 = look_at_pos + offset

						# Smooth camera position
						camera.global_transform.origin = target_pos
						# Instantly look at look point
						camera.look_at(look_at_pos, Vector3.UP)
			C_CameraTarget.Mode.FREE:
				# Camera movement handled by input script or other system
				pass
			C_CameraTarget.Mode.CINEMATIC:
				# Camera position/rotation set by cutscene logic or animation
				pass
