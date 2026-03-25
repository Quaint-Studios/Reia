class_name ClientMain extends Node

## The Root Node for the Client Presentation Layer.
## Responsible for connecting to the server, registering visual Observers,
## and ticking the Client-side prediction ECS.

func _ready() -> void:
	print("[CLIENT] Starting Client Initialization...")
	
	ECS.world = World.new()
	
	# Register Client-Only ECS Systems (Interpolation & Prediction)
	ECS.world.add_system(ClientInterpolationSystem.new())
	
	# Register Global Observers (The Bridge to Visuals)
	# These listen to ECS math and trigger UI updates, Sounds, and VFX
	ECS.world.add_observer(InventoryUIObserver.new())
	ECS.world.add_observer(HealthUIObserver.new())
	ECS.world.add_observer(ZoneAudioObserver.new())
	ECS.world.add_observer(CombatVFXObserver.new())
	ECS.world.add_observer(AnimationStateObserver.new())
	
	# Initialize Client Network 
	# (Does not connect yet, just prepares the sockets)
	# NetworkCore.init_client()
	
	print("[CLIENT] ECS & Observers Initialized. Routing to Title Screen...")
	
	# Hand off visual control to the SceneManager to load the first UI
	# We use call_deferred to ensure the tree is stable before swapping scenes
	call_deferred("_route_to_title")

func _route_to_title() -> void:
	SceneManager.transition_to_screen(Scenes.Menus.TITLE_SCREEN)

## TICKING THE CLIENT
## We use _process on the client. The client needs to interpolate visuals 
## as smoothly as possible, scaling with the user's frame rate (60fps, 144fps, etc).
func _process(delta: float) -> void:
	ECS.process(delta)
