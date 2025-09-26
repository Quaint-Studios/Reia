extends Node

@onready var world: World = $World

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ECS.world = world

	# Spawn player entity
	var player_entity: Entity = preload("res://ecs/entities/player/Player.tscn").instantiate()

	# Add to world
	world.add_entity(player_entity)

	# Position player, you can't get the component before it's added to the world
	var transform_comp: C_Transform = player_entity.get_component(C_Transform)

	# Manipulate the transform component directly
	transform_comp.transform.origin = Vector3(-5, 1, -5)

	# Sync the component back to the node if it's not already being synced by a system
	ECSUtils.sync_component_to_transform(player_entity)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	world.process(delta, 'gameplay')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	world.process(delta, 'physics')
