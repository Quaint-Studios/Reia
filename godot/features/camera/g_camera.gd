class_name CameraGlobal

var camera_state: CameraStateData = CameraStateData.new()

# Camera Nodes
var target: Node3D = null

var root: Node3D = null

var yaw_pivot: Node3D = null
var pitch_pivot: Node3D = null
var spring_arm: SpringArm3D = null
var camera: Camera3D = null

# Cached Components

func process(_delta: float) -> void:
	if not LocalCache.is_valid():
		load_player()

		if not LocalCache.is_valid():
			return

	if root == null:
		camera = LocalCache.get_viewport().get_camera_3d()
		if camera == null:
			return
		spring_arm = camera.get_parent() as SpringArm3D
		pitch_pivot = spring_arm.get_parent() as Node3D
		yaw_pivot = pitch_pivot.get_parent() as Node3D
		root = yaw_pivot.get_parent() as Node3D
		return

	if target == null:
		target = LocalCache.player_node
		if target == null:
			return


func physics_process(_delta: float) -> void:
	if not LocalCache.is_valid():
		return

	if root == null:
		return

	# Update camera transforms
	root.global_transform.origin = target.global_transform.origin + camera_state.offset
	yaw_pivot.rotation.y = deg_to_rad(camera_state.yaw)
	pitch_pivot.rotation.x = deg_to_rad(camera_state.pitch)
	spring_arm.spring_length = camera_state.distance
	camera.fov = camera_state.fov


func load_player() -> void:
	if ECS.world == null:
		return

	var player_entity := ECS.world.query.with_all([C_LocalPlayer]).execute_one()
	if player_entity != null:
		LocalCache.set_player(player_entity)
