class_name WorldRoot extends Node3D

const GROUP_INPUT: StringName = &"input"
const GROUP_GAMEPLAY: StringName = &"gameplay"
const GROUP_PHYSICS: StringName = &"physics"
const GROUP_INVENTORY: StringName = &"inventory"

var world: World

func _ready() -> void:
	world = World.new()
	world.name = "ECS World"
	add_child(world)
	ECS.world = world

	_register_systems()
	_register_observers()

func _process(delta: float) -> void:
	world.process(delta, GROUP_INPUT)
	world.process(delta, GROUP_GAMEPLAY)
	world.process(delta, GROUP_INVENTORY)

func _physics_process(delta: float) -> void:
	world.process(delta, GROUP_PHYSICS)

func _register_systems() -> void:
	pass

func _register_observers() -> void:
	pass
