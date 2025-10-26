class_name CameraRigObserver
extends Observer

func watch() -> Resource:
	return C_CameraRigRef

func on_component_added(entity: Entity, component: Resource) -> void:
	_validate_and_cache(entity, component as C_CameraRigRef)

func on_component_changed(entity: Entity, component: Resource, _property: String, _new_value: Variant, _old_value: Variant) -> void:
	_validate_and_cache(entity, component as C_CameraRigRef)

func _validate_and_cache(node: Node, rig: C_CameraRigRef) -> void:
	var ok := true
	if rig.root_path and not node.has_node(rig.root_path): ok = false
	if rig.yaw_pivot_path and not node.has_node(rig.yaw_pivot_path): ok = false
	if rig.pitch_pivot_path and not node.has_node(rig.pitch_pivot_path): ok = false
	if rig.spring_arm_path and not node.has_node(rig.spring_arm_path): ok = false
	if rig.camera_path and not node.has_node(rig.camera_path): ok = false

	if not ok:
		push_warning("CameraRigObserver: One or more rig NodePaths are invalid on %s" % node.name)
		return

	# Cache references
	if rig.root_path: rig.root = node.get_node(rig.root_path) as Node3D
	if rig.yaw_pivot_path: rig.yaw = node.get_node(rig.yaw_pivot_path) as Node3D
	if rig.pitch_pivot_path: rig.pitch = node.get_node(rig.pitch_pivot_path) as Node3D
	if rig.spring_arm_path: rig.spring = node.get_node(rig.spring_arm_path) as SpringArm3D
	if rig.camera_path: rig.camera = node.get_node(rig.camera_path) as Camera3D
