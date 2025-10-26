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

	var camera := preload("res://features/camera/player_camera.tscn").instantiate() as Camera3D
	add_child(camera)

	var mouse_mode := MouseMode.new()
	mouse_mode.name = "MouseMode"
	camera.add_child(mouse_mode)

	var npc := preload("res://features/npc/e_npc.tscn").instantiate() as Npc
	world.add_entity(npc)
	ECSUtils.update_transform(npc, Vector3(5, 1, 5))
	#endregion

	#region Systems
	var camera_input_system := CameraInputSystem.new()
	camera_input_system.name = "CameraInputSystem"
	camera_input_system.group = GROUP_INPUT
	world.add_system(camera_input_system)

	var camera_follow_system := CameraFollowSystem.new()
	camera_follow_system.name = "CameraFollowSystem"
	camera_follow_system.camera_node_path = camera.get_path()
	camera_follow_system.group = GROUP_GAMEPLAY
	world.add_system(camera_follow_system)

	var aim_animation_system := AimAnimationSystem.new()
	aim_animation_system.name = "AimAnimationSystem"
	aim_animation_system.group = GROUP_GAMEPLAY
	world.add_system(aim_animation_system)
	#endregion

	#region Observers
	var transform_observer := TransformObserver.new()
	transform_observer.name = "TransformObserver"
	world.add_observer(transform_observer)
	#region


func _process(delta: float) -> void:
	world.process(delta, GROUP_INPUT)
	world.process(delta, GROUP_GAMEPLAY)

func _physics_process(delta: float) -> void:
	world.process(delta, GROUP_PHYSICS)

# # Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	_setup_world()

# 	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# 	# Spawn player entity
# 	var player_tscn := preload("res://features/player/Player.tscn").instantiate()
# 	var e_player: Entity = player_tscn
# 	world.add_entity(e_player)

# 	var player: CharacterBody3D = player_tscn
# 	var body_ref: C_CharacterBodyRef = e_player.get_component(C_CharacterBodyRef)
# 	body_ref.node = player

# 	# Setup camera entity
# 	var camera_tscn: PlayerCamera = preload("res://features/camera/player_camera.tscn").instantiate()
# 	camera_tscn.name = "PlayerCamera"
# 	camera_tscn.set_target(player)
# 	add_child(camera_tscn)

# func _setup_world() -> void:
# 	ECS.world = world

# 	# Create system groups for organization and scheduling
# 	const GROUP_GAMEPLAY: String = "gameplay"
# 	const GROUP_PHYSICS: String = "physics"

# 	# Instantiate input and movement systems
# 	var input_system := PlayerInputSystem.new()
# 	input_system.name = "PlayerInputSystem"
# 	var movement_system := PlayerMovementSystem.new()
# 	movement_system.name = "PlayerMovementSystem"
# 	var dash_system := DashAbilitySystem.new()
# 	dash_system.name = "DashAbilitySystem"
# 	var player_ability_system := PlayerAbilitySystem.new()
# 	player_ability_system.name = "PlayerAbilitySystem"
# 	var fireball_system := FireballSystem.new()
# 	fireball_system.name = "FireballSystem"


# 	# Assign systems to groups for scheduling
# 	input_system.group = GROUP_GAMEPLAY
# 	movement_system.group = GROUP_PHYSICS
# 	dash_system.group = GROUP_GAMEPLAY
# 	player_ability_system.group = GROUP_PHYSICS
# 	fireball_system.group = GROUP_PHYSICS

# 	# Register systems with the world
# 	world.add_system(input_system)
# 	world.add_system(movement_system)
# 	world.add_system(dash_system)
# 	world.add_system(player_ability_system)
# 	world.add_system(fireball_system)

# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	world.process(delta, 'gameplay')


# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _physics_process(delta: float) -> void:
# 	world.process(delta, 'physics')
