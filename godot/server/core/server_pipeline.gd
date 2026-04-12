class_name ServerPipeline

## Constructs the entire authoritative Server ECS architecture.
static func build(world: World) -> void:
	# Core Observers
	# Automates the EntityMap.server O(1) lookups whenever an entity gets a C_NetworkId
	world.add_observer(NetworkIdObserver.new(EntityMap.server))

	# Network Receivers (PRE_PROCESS)
	_register_network_receivers(world)

	# Core Simulation Math
	_register_physics(world)
	_register_inventory(world)
	_register_combat(world)
	_register_ai(world)
	_register_spawning(world)

	# Network Broadcasters (SPAWNING / POST_PROCESS)
	_register_network_broadcasters(world)


static func _register_network_receivers(world: World) -> void:
	var mov_net := ServerMovementNetworkSystem.new()
	mov_net.group = SystemGroups.PRE_PROCESS
	world.add_system(mov_net)

	var combat_net := ServerCombatNetworkSystem.new()
	combat_net.group = SystemGroups.PRE_PROCESS
	world.add_system(combat_net)

	# TODO: ...
	# var inv_net := InventoryNetworkSystem.new()
	# inv_net.group = SystemGroups.PRE_PROCESS
	# world.add_system(inv_net)

static func _register_physics(world: World) -> void:
	var char_physics := ServerCharacterPhysicsSystem.new()
	char_physics.group = SystemGroups.PHYSICS
	world.add_system(char_physics)

	var kin_physics := ServerKinematicPhysicsSystem.new()
	kin_physics.group = SystemGroups.PHYSICS
	world.add_system(kin_physics)


static func _register_inventory(world: World) -> void:
	var validator := BankAccessValidator.new()
	validator.group = SystemGroups.VALIDATION
	world.add_system(validator)

	var execution := InventoryExecutionSystem.new()
	execution.group = SystemGroups.EXECUTION
	world.add_system(execution)

static func _register_combat(world: World) -> void:
	var dmg := DamageCalculationSystem.new()
	dmg.group = SystemGroups.COMBAT
	world.add_system(dmg)

static func _register_ai(world: World) -> void:
	var ai := MonsterAISystem.new()
	ai.group = SystemGroups.AI
	world.add_system(ai)

static func _register_spawning(world: World) -> void:
	var spawner := SpawnerSystem.new()
	spawner.group = SystemGroups.SPAWNING
	world.add_system(spawner)

static func _register_network_broadcasters(world: World) -> void:
	var state_sync := ServerStateSyncSystem.new()
	# Runs at the very end of the frame after all movement and combat logic is done
	state_sync.group = SystemGroups.POST_PROCESS
	world.add_system(state_sync)
