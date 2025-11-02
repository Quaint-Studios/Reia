extends Node3D

var world: World = World.new()

const GROUP_GAMEPLAY: String = "gameplay"
const GROUP_INPUT: String = "input"
const GROUP_PHYSICS: String = "physics"

func _ready() -> void:
	world.name = "ECS World"
	add_child(world)
	ECS.world = world

	_register_systems()
	_register_observers()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	#region Spawn
	var player := preload("res://features/player/e_player.tscn").instantiate() as Player
	world.add_entity(player)
	player.add_component(C_LocalPlayer.new())
	ECSUtils.update_transform(player, Vector3(0, 1, 0))

	var camera := preload("res://features/camera/camera.tscn").instantiate()
	add_child(camera)

	var npc := preload("res://features/npc/e_npc.tscn").instantiate() as Npc
	world.add_entity(npc)
	ECSUtils.update_transform(npc, Vector3(5, 0.5, 5))
	#endregion

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

	# var camera_input := CameraInputSystem.new()
	# camera_input.name = "CameraInputSystem"
	# camera_input.group = GROUP_INPUT
	# world.add_system(camera_input)

	# GAMEPLAY

	# PHYSICS
	var player_move := PlayerMovementSystem.new()
	player_move.name = "PlayerMovementSystem"
	player_move.group = GROUP_PHYSICS
	world.add_system(player_move)

func _register_observers() -> void:
	var transform_observer := TransformObserver.new()
	transform_observer.name = "TransformObserver"
	world.add_observer(transform_observer)
