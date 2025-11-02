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

func physics_process(delta: float) -> void:
	if not LocalCache.is_valid() or root == null or not (target is CharacterBody3D):
		return

	var body := target as CharacterBody3D
	var planar_velocity := body.get_real_velocity()
	planar_velocity.y = 0.0

	var rig_forward := (-yaw_pivot.global_transform.basis.z).normalized()
	var rig_right := yaw_pivot.global_transform.basis.x.normalized()

	var forward_speed := planar_velocity.dot(rig_forward)
	var lateral_speed := planar_velocity.dot(rig_right)

	var target_forward := log(1.0 + absf(forward_speed) * FORWARD_SPEED_SCALE / 10000.0)
	target_forward *= signf(forward_speed)
	target_forward = clampf(target_forward, -OFFSET_FORWARD_IN_CAP, OFFSET_FORWARD_OUT_CAP)

	var target_lateral := log(1.0 + absf(lateral_speed) * LATERAL_SPEED_SCALE / 10000.0)
	target_lateral *= signf(lateral_speed)
	target_lateral = clampf(target_lateral, -OFFSET_LATERAL_CAP, OFFSET_LATERAL_CAP)

	var forward_factor := clampf(FORWARD_SMOOTH * delta, 0.0, 1.0)
	var lateral_factor := clampf(LATERAL_SMOOTH * delta, 0.0, 1.0)

	current_forward_offset = lerpf(current_forward_offset, target_forward, forward_factor)
	current_lateral_offset = lerpf(current_lateral_offset, target_lateral, lateral_factor)

	var desired := target.global_transform.origin + camera_state.offset
	desired -= rig_forward * current_forward_offset
	desired -= rig_right * current_lateral_offset

	var position_factor := clampf(camera_state.position_smooth * delta, 0.0, 1.0)
	root.global_transform.origin = root.global_transform.origin.lerp(desired, position_factor)

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
