class_name ClientPipeline

## Constructs the Presentation Client ECS architecture and Observers.
## The client handles prediction, interpolation, and visual reactions.

static func build(world: World) -> void:
	# Core Observers (Data Mapping & Visual Reactions)
	_register_observers(world)

	# Network Receivers
	_register_network_receivers(world)

	# Systems (Math & Prediction)
	_register_prediction_systems(world)

static func _register_observers(world: World) -> void:
	# Automates EntityMap.client O(1) lookups
	world.add_observer(NetworkIdObserver.new(EntityMap.client))

	# Visual / Audio Observers
	world.add_observer(InventoryUIObserver.new())
	world.add_observer(HealthUIObserver.new())
	world.add_observer(ZoneAudioObserver.new())
	world.add_observer(CombatVFXObserver.new())
	world.add_observer(AnimationStateObserver.new())

static func _register_network_receivers(world: World) -> void:
	# Reads the STATE_SYNC packets from the Server and updates C_NetworkSync
	var state_sync := ClientStateSyncSystem.new()
	state_sync.group = SystemGroups.PRE_PROCESS
	world.add_system(state_sync)

static func _register_prediction_systems(world: World) -> void:
	# Smoothly lerps visual Godot nodes to match C_NetworkSync targets
	var interp := ClientInterpolationSystem.new()
	interp.group = SystemGroups.PRE_PROCESS
	world.add_system(interp)
