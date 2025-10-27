extends Node3D

@onready var world: World = $World

const GROUP_GAMEPLAY: String = "gameplay"
const GROUP_INPUT: String = "input"
const GROUP_PHYSICS: String = "physics"

func _ready() -> void:
	ECS.world = world

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	#region Spawn
	var player := preload("res://features/player/e_player.tscn").instantiate() as Player
	world.add_entity(player)
	player.add_component(C_LocalPlayer.new())
	ECSUtils.update_transform(player, Vector3(0, 1, 0))

	var camera := preload("res://features/camera/e_camera.tscn").instantiate() as Camera
	world.add_entity(camera)
	(camera.find_child("CameraInput", false) as CameraInput).setup(camera, player)

	var npc := preload("res://features/npc/e_npc.tscn").instantiate() as Npc
	world.add_entity(npc)
	ECSUtils.update_transform(npc, Vector3(5, 1, 5))
	#endregion

	_register_systems()
	_register_observers()

func _process(delta: float) -> void:
	world.process(delta, GROUP_INPUT)
	world.process(delta, GROUP_GAMEPLAY)

func _physics_process(delta: float) -> void:
	world.process(delta, GROUP_PHYSICS)

func _register_systems() -> void:
	# INPUT
	var move_input := PlayerMovementInputSystem.new()
	move_input.name = "PlayerMovementInputSystem"
	move_input.group = GROUP_INPUT
	world.add_system(move_input)

	var camera_input := CameraInputSystem.new()
	camera_input.name = "CameraInputSystem"
	camera_input.group = GROUP_INPUT
	world.add_system(camera_input)

	# GAMEPLAY
	var cam_mode := CameraModeBlendSystem.new()
	cam_mode.name = "CameraModeBlendSystem"
	cam_mode.group = GROUP_GAMEPLAY
	world.add_system(cam_mode)

	var cam_kin := CameraKinematicsSystem.new()
	cam_kin.name = "CameraKinematicsSystem"
	cam_kin.group = GROUP_GAMEPLAY
	world.add_system(cam_kin)

	var cam_rot := CameraRotationSystem.new()
	cam_rot.name = "CameraRotationSystem"
	cam_rot.group = GROUP_GAMEPLAY
	world.add_system(cam_rot)

	var player_move := PlayerMovementSystem.new()
	player_move.name = "PlayerMovementSystem"
	player_move.group = GROUP_PHYSICS
	world.add_system(player_move)

	var aim_anim := AimAnimationSystem.new()
	aim_anim.name = "AimAnimationSystem"
	aim_anim.group = GROUP_GAMEPLAY
	world.add_system(aim_anim)

	# PHYSICS
	var cam_col := CameraCollisionSystem.new()
	cam_col.name = "CameraCollisionSystem"
	cam_col.group = GROUP_PHYSICS
	world.add_system(cam_col)

func _register_observers() -> void:
	var transform_observer := TransformObserver.new()
	transform_observer.name = "TransformObserver"
	world.add_observer(transform_observer)

	# If you added the rig observer earlier
	# var rig_observer := CameraRigObserver.new()
	# rig_observer.name = "CameraRigObserver"
	# world.add_observer(rig_observer)
