class_name CameraSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_CameraTarget, C_CameraRef])

func process(entity: Entity, _delta: float) -> void:
	var camera_target: C_CameraTarget = entity.get_component(C_CameraTarget)
	var camera_ref: C_CameraRef = entity.get_component(C_CameraRef)
	var camera: Camera3D = camera_ref.node

	match camera_target.mode:
		0: # Follow
			if camera_target.target_entity:
				var target_body: C_CharacterBodyRef = camera_target.target_entity.get_component(C_CharacterBodyRef)
				if target_body and target_body.node:
					camera.global_transform.origin = target_body.node.global_transform.origin + Vector3(0, 2, -6)
		1: # Free
			# Camera movement handled by input script
			pass
		2: # Cinematic
			# Camera position/rotation set by cutscene logic
			pass
