class_name ServerPipeline

## Constructs the entire authoritative Server ECS architecture.
static func build(world: World) -> void:
	_register_network_receivers(world)
	_register_physics(world)
	_register_inventory(world)
	_register_combat(world)
	_register_ai(world)
	_register_spawning(world)

	world.add_observer(NetworkIdObserver.new())

static func _register_network_receivers(world: World) -> void:
	var mov_net := MovementNetworkSystem.new()
	mov_net.group = SystemGroups.PRE_PROCESS
	world.add_system(mov_net)

	var combat_net := CombatNetworkSystem.new()
	combat_net.group = SystemGroups.PRE_PROCESS
	world.add_system(combat_net)

	# TODO: ...
	# var inv_net := InventoryNetworkSystem.new()
	# inv_net.group = SystemGroups.PRE_PROCESS
	# world.add_system(inv_net)

static func _register_physics(world: World) -> void:
	var physics := ServerPhysicsSystem.new()
	physics.group = SystemGroups.PHYSICS
	world.add_system(physics)

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
