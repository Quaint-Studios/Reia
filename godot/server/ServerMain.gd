class_name ServerMain extends Node

## The Root Node for the Dedicated Server.
## Responsible for Database connections, Network Listening, and ticking the
## Authoritative ECS Simulation.

var world: World = World.new()
const SERVER_PORT = 7777

var rust_core: RustCore

func _ready() -> void:
	if not NetworkRouter.offline_mode:
		print("[SERVER] Starting Server Initialization...")

		# DatabaseCore.connect_to_db()
		# print("[SERVER] Database connected.")

		# Start server
		rust_core = RustCore.new()
		add_child(rust_core)

		rust_core.start_backend(SERVER_PORT)
	else:
		print("[SERVER] Offline mode enabled. Skipping network initialization.")

	# Create GECS World
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
	# DRAIN THE FLUME CHANNEL
	# This pulls thousands of network events processed by Tokio
	# and safely fires the connected signals on the main thread.
	if rust_core and not NetworkRouter.offline_mode:
		rust_core.poll_network()

	# Strict, Explicit Server Pipeline (No looping overhead, profilable)
	ECS.world.process(delta, SystemGroups.PRE_PROCESS)
	ECS.world.process(delta, SystemGroups.PHYSICS)
	ECS.world.process(delta, SystemGroups.VALIDATION)
	ECS.world.process(delta, SystemGroups.EXECUTION)
	ECS.world.process(delta, SystemGroups.COMBAT)
	ECS.world.process(delta, SystemGroups.AI)


	# Late Phase (Respawning)
	ECS.world.process(delta, SystemGroups.SPAWNING)

	# WRITE NETWORK
	# Systems during the tick have called NetworkRouter.queue_packet(...)
	# Now we flush the giant flattened buffers back to Rust in one FFI call.
	NetworkRouter.flush_outbox()

	# CLEANUP
	# Wipe the inbox clean for the next frame.
	NetworkRouter.clear_inbox()


	# Broadcast state chunks to connected clients
	# ChunkManager.broadcast_updates()
