extends Node

@onready var world: World = $World

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup_world()

	# Spawn player entity
	var player_tscn := preload("res://entities/player/Player.tscn").instantiate()
	var e_player: Entity = player_tscn
	world.add_entity(e_player)

	var player: CharacterBody3D = player_tscn
	var body_ref: C_CharacterBodyRef = e_player.get_component(C_CharacterBodyRef)
	body_ref.node = player

func _setup_world() -> void:
	ECS.world = world

	# Create system groups for organization and scheduling
	const GROUP_GAMEPLAY: String = "gameplay"
	const GROUP_PHYSICS: String = "physics"

	# Instantiate input and movement systems
	var input_system := PlayerInputSystem.new()
	input_system.name = "PlayerInputSystem"
	var movement_system := PlayerMovementSystem.new()
	movement_system.name = "PlayerMovementSystem"

	# Assign systems to groups for scheduling
	input_system.group = GROUP_GAMEPLAY
	movement_system.group = GROUP_PHYSICS

	# Register systems with the world
	world.add_system(input_system)
	world.add_system(movement_system)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	world.process(delta, 'gameplay')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	world.process(delta, 'physics')
