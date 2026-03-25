## res://server/server_main.gd
class_name ServerMain extends Node

## The Root Node for the Dedicated Server.
## Responsible for Database connections, Network Listening, and ticking the
## Authoritative ECS Simulation.

var world: World = World.new()
const SERVER_PORT = 7777

func _ready() -> void:
	print("[SERVER] Starting Server Initialization...")

	# DatabaseCore.connect_to_db()
	print("[SERVER] Database connected.")

	world.name = "ServerWorld"
	add_child(world)
	ECS.world = world

	# Builds the entire deterministic architecture instantly
	ServerPipeline.build(ECS.world)

	# NetworkCore.start_server(SERVER_PORT)
	print("[SERVER] Listening for clients on port %d" % SERVER_PORT)


## TICKING THE SERVER
## TODO: Implement proper ticking
func _physics_process(delta: float) -> void:
	# Gather network inputs
	# NetworkCore.poll()
	# Strict, Explicit Server Pipeline (No looping overhead, profilable)
	ECS.world.process(delta, SystemGroups.PRE_PROCESS)
	ECS.world.process(delta, SystemGroups.PHYSICS)
	ECS.world.process(delta, SystemGroups.VALIDATION)
	ECS.world.process(delta, SystemGroups.EXECUTION)
	ECS.world.process(delta, SystemGroups.COMBAT)
	ECS.world.process(delta, SystemGroups.AI)

	# Flush things if needed here

	# Late Phase (Respawning)
	ECS.world.process(delta, SystemGroups.SPAWNING)

	# 5. Broadcast state chunks to connected clients
	# ChunkManager.broadcast_updates()
