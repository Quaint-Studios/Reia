class_name ClientMain extends Node

## The Root Node for the Client Presentation Layer.
## Responsible for connecting to the server, registering visual Observers,
## and ticking the Client-side prediction ECS.

var world: World = World.new()

func _ready() -> void:
	print("[CLIENT] Starting Client Initialization...")
	world.name = "ClientWorld"
	add_child(world)
	ECS.world = world

	# Builds prediction systems and visual observers instantly
	ClientPipeline.build(ECS.world)

	# NetworkCore.init_client()

	print("[CLIENT] ECS & Observers Initialized. Routing to Title Screen...")
	call_deferred("_route_to_title")

func _route_to_title() -> void:
	# Uses our auto-generated registry for perfect IDE autocomplete
	SceneManager.transition_to_screen(Scenes.Menus.TITLE_SCREEN)


## TICKING THE CLIENT
func _process(delta: float) -> void:
	# Read network state from Server
	# NetworkCore.poll()
	# Execute Prediction Math (Interpolation)
	ECS.world.process(delta, SystemGroups.PRE_PROCESS)

	# Flush things if needed here
