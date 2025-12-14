class_name CameraGlobal

var camera_state: CameraStateData = CameraStateData.new()

# Camera Nodes
var target: Node3D = null

var root: Node3D = null

var yaw_pivot: Node3D = null
var pitch_pivot: Node3D = null
var spring_arm: SpringArm3D = null
var camera: Camera3D = null

# Variables
var current_forward_offset: float = 0.0
var current_lateral_offset: float = 0.0

const POSITION_SMOOTH: float = 8.0
const FORWARD_SMOOTH: float = 18.0
const LATERAL_SMOOTH: float = 18.0

const FORWARD_SPEED_SCALE: float = 0.085
const LATERAL_SPEED_SCALE: float = 0.12

const OFFSET_FORWARD_OUT_CAP: float = 6.0
const OFFSET_FORWARD_IN_CAP: float = 3.0
const OFFSET_LATERAL_CAP: float = 2.5

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

	if not LocalCache.is_valid() or root == null or not (target is CharacterBody3D):
		return

	root.global_transform.origin = target.global_transform.origin + camera_state.offset

	yaw_pivot.rotation.y = deg_to_rad(camera_state.yaw)
	pitch_pivot.rotation.x = deg_to_rad(camera_state.pitch)
	spring_arm.spring_length = camera_state.distance
	camera.fov = camera_state.fov

func physics_process(_delta: float) -> void:
	pass


func load_player() -> void:
	if ECS.world == null:
		return

	var player_entity := ECS.world.query.with_all([C_LocalPlayer]).execute_one()
	if player_entity != null:
		LocalCache.set_player(player_entity)
