class_name ServerMain extends Node

## The Root Node for the Dedicated Server.
## Responsible for Database connections, Network Listening, and ticking the
## Authoritative ECS Simulation (Physics, AI, Combat Math).

const SERVER_PORT = 7777

func _ready() -> void:
	print("[SERVER] Starting Server Initialization...")

	# 1. Initialize Database Connections
	# DatabaseCore.connect_to_db()
	print("[SERVER] Database connected.")

	# 2. Setup the Global ECS World
	ECS.world = World.new()

	# 3. Register Server-Only & Shared ECS Systems
	# We process these in a specific pipeline order (Movement -> Logic -> Combat -> Spawning)
	ECS.world.add_system(ServerPhysicsSystem.new())
	ECS.world.add_system(BankAccessValidator.new())
	ECS.world.add_system(InventoryExecutionSystem.new())
	ECS.world.add_system(DamageCalculationSystem.new())
	ECS.world.add_system(MonsterAISystem.new())
	ECS.world.add_system(SpawnerSystem.new())

	# 4. Initialize Network Listening
	# NetworkCore.start_server(SERVER_PORT)
	print("[SERVER] Listening for clients on port %d" % SERVER_PORT)

## TICKING THE SERVER
## We use _physics_process on the server. MMO servers must tick at a fixed
## rate (e.g., 20 or 30 ticks per second) for deterministic physics and combat.
func _physics_process(delta: float) -> void:
	# 1. Process all incoming network packets
	# NetworkCore.poll()
	# 2. Execute the GECS Simulation Pipeline
	ECS.world.tick(delta)

	# 3. Flush the Command Buffer (Spawning entities, adding components)
	ECS.cmd.flush()

	# 4. Broadcast state changes to clients via Spatial Chunking
	# ChunkManager.broadcast_updates()
