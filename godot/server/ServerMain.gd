class_name ServerMain extends Node

## The Root Node for the Dedicated Server.
## Responsible for Database connections, Network Listening, and ticking the
## Authoritative ECS Simulation.

var world: World = World.new()
const SERVER_PORT = 7777

var rust_core: RustCore

func _ready() -> void:
	print("[SERVER] Starting Server Initialization...")

	# DatabaseCore.connect_to_db()
	# print("[SERVER] Database connected.")

	rust_core = RustCore.new()
	add_child(rust_core)

	UIUtils.safe_connect(
		rust_core.on_network_event,
		_on_rust_packet_received,
		"ServerMain rust_core.on_network_event"
	)

	rust_core.start_backend(SERVER_PORT)

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
	rust_core.poll_network()

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

	# Broadcast state chunks to connected clients
	# ChunkManager.broadcast_updates()

func _on_rust_packet_received(_client_id: int, _op_code: StringName, _payload: PackedByteArray) -> void:
	# Parse the binary payload using Godot's StreamPeerBuffer (or rkyv bindings)
	# and push it to the GECS NetworkEventQueue!
	pass
