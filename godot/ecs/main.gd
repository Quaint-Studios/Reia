extends Node

@onready var world: World = $World

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ECS.world = world

	# Spawn player entity
	var player_entity: Entity = preload("res://ecs/entities/player/Player.tscn").instantiate()
	world.add_entity(player_entity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	world.process(delta, 'gameplay')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	world.process(delta, 'physics')
