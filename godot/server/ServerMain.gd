class_name ServerMain extends Node

## The Root Node for the Dedicated Server.
## Responsible for Database connections, Network Listening, and ticking the
## Authoritative ECS Simulation (Physics, AI, Combat Math).

const SERVER_PORT = 7777
var command_buffer: CommandBuffer

func _ready() -> void:
	print("[SERVER] Starting Server Initialization...")

	# DatabaseCore.connect_to_db()
	print("[SERVER] Database connected.")
	
	ECS.world = World.new()

	# We process these in a specific pipeline order (Movement -> Logic -> Combat -> Spawning)
	ECS.world.add_system(ServerPhysicsSystem.new())
	ECS.world.add_system(BankAccessValidator.new())
	ECS.world.add_system(InventoryExecutionSystem.new())
	ECS.world.add_system(DamageCalculationSystem.new())
	ECS.world.add_system(MonsterAISystem.new())
	ECS.world.add_system(SpawnerSystem.new())

	# NetworkCore.start_server(SERVER_PORT)
	print("[SERVER] Listening for clients on port %d" % SERVER_PORT)

## TICKING THE SERVER
## We use _physics_process on the server. MMO servers must tick at a fixed
## rate (e.g., 20 or 30 ticks per second) for deterministic physics and combat.
func _physics_process(delta: float) -> void:
	# NetworkCore.poll()
	# TODO: Calculate the tick
	ECS.world.process(delta, WorldRoot.GROUP_PHYSICS)

	# ChunkManager.broadcast_updates()
