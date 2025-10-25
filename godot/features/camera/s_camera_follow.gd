class_name CameraFollowSystem
extends System

@export var camera_node_path: NodePath

var camera: Camera3D = null

func _ready() -> void:
	if camera != null:
		push_warning("CameraFollowSystem: Camera already assigned, skipping resolution.")
		return

	if camera_node_path and has_node(camera_node_path):
		camera = get_node(camera_node_path) as Camera3D
		return

	if get_viewport().get_camera_3d() != null:
		camera = get_viewport().get_camera_3d()
		return

	push_warning("CameraFollowSystem: No camera found at path '%s' and no viewport camera available." % camera_node_path)

func query() -> QueryBuilder:
	return q.with_all([C_LocalPlayer, C_AimState, C_CameraState, C_Transform]).iterate([C_AimState, C_CameraState, C_Transform])

func process(entities: Array[Entity], components: Array[Array], _delta: float) -> void:
	if camera == null or entities.is_empty():
		return

	var aims := components[0] as Array
	var cams := components[1] as Array
	var trs := components[2] as Array

	for i in range(entities.size()):
		var aim: C_AimState = aims[i]
		var cam: C_CameraState = cams[i]
		var t: C_Transform = trs[i]

		var focus: Vector3 = t.position + cam.look_point_offset
		var basis := Basis.IDENTITY
		basis = basis.rotated(Vector3.UP, aim.yaw)
		basis = basis.rotated(basis.x, aim.pitch)
		var offset := basis * Vector3(0, 0, -cam.zoom)
		var desired_position := focus + offset
		camera.global_transform.origin = desired_position
		camera.look_at(focus, Vector3.UP)
