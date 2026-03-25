class_name ClientPipeline

## Constructs the Presentation Client ECS architecture and Observers.
static func build(world: World) -> void:
	# Systems (Math & Prediction)
	var interp := ClientInterpolationSystem.new()
	interp.group = SystemGroups.PRE_PROCESS
	world.add_system(interp)
	
	# Observers (Visual/Audio Reactions)
	# Observers do not need strict groups because they react to data changes 
	# dynamically rather than iterating over arrays of entities every tick.
	world.add_observer(InventoryUIObserver.new())
	world.add_observer(HealthUIObserver.new())
	world.add_observer(ZoneAudioObserver.new())
	world.add_observer(CombatVFXObserver.new())
	world.add_observer(AnimationStateObserver.new())
