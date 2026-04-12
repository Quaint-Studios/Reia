class_name ServerMain extends Node

## The Root Node for the Dedicated Server.
## Responsible for Database connections, Network Listening, and ticking the
## Authoritative ECS Simulation.

var port: int
var is_offline: bool

var rust_core: RustCore

func _init(_port: int, _offline: bool = false) -> void:
	port = _port
	is_offline = _offline
	name = "ServerMain"

func _ready() -> void:
	# Create GECS World
	var world := World.new()
	world.name = "ServerWorld"
	GameOrchestrator.server_world = world

	# Builds the entire deterministic architecture instantly
	ServerPipeline.build(world)

	if not is_offline:
		print("[SERVER] Starting Server Initialization...")

		# Start server
		rust_core = RustCore.new()
		add_child(rust_core)
		UIUtils.safe_connect(rust_core.on_network_events, _on_rust_packets, "ServerMain on_network_events")
		rust_core.start_backend(port)

		print("[SERVER] Listening for clients on port %d" % port)
	else:
		print("[SERVER] Offline mode enabled. Skipping network initialization.")

func _on_rust_packets(buckets: Dictionary) -> void:
	NetworkRouter.server.incoming_buckets = buckets

## TICKING THE SERVER
## TODO: Implement proper ticking
func _physics_process(delta: float) -> void:
	# DRAIN THE FLUME CHANNEL
	# This pulls thousands of network events processed by Tokio
	# and safely fires the connected signals on the main thread.
	if rust_core:
		rust_core.poll_network()

	var world := GameOrchestrator.server_world

	if not world:
		return

	# Strict, Explicit Server Pipeline (No looping overhead, profilable)
	world.process(delta, SystemGroups.PRE_PROCESS)
	world.process(delta, SystemGroups.PHYSICS)
	world.process(delta, SystemGroups.VALIDATION)
	world.process(delta, SystemGroups.EXECUTION)
	world.process(delta, SystemGroups.COMBAT)
	world.process(delta, SystemGroups.AI)

	# Late Phase (Respawning)
	world.process(delta, SystemGroups.SPAWNING)

	# Post Process (Network Broadcasting, VFX triggering)
	world.process(delta, SystemGroups.POST_PROCESS)

	# Safely flush to the Rust network thread
	NetworkRouter.server.flush_to_rust(rust_core)
	NetworkRouter.server.clear_inbox()
