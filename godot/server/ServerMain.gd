class_name ServerMain extends Node

## The Root Node for the Dedicated Server.
## Responsible for Database connections, Network Listening, and ticking the
## Authoritative ECS Simulation.

var port: int
var is_offline: bool

var rust_core: RustCore

func _init(_port: int = 7777, _offline: bool = false) -> void:
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

	# Load stripped map collision scene for headless server physics execution
	var map_path: String = Zone.MAP_PATHS.get(Zone.ID.WATERBROOK, "")
	if map_path != "":
		var stripped_map: PackedScene = ServerPrefabCache.get_stripped_map_scene(map_path)
		if stripped_map:
			var map_node: Node = stripped_map.instantiate()
			add_child(map_node)
			print("[SERVER] Loaded stripped headless map collision: %s" % map_path)

	if not is_offline:
		print("[SERVER] Starting Server Initialization...")

		# Start server
		rust_core = RustCore.new()
		add_child(rust_core)
		UIUtils.safe_connect(rust_core.on_network_events, _on_rust_packets, "ServerMain on_network_events")

		# Bind network lifecycle signals
		UIUtils.safe_connect(rust_core.on_server_client_connected, _on_client_connected, "ServerMain on_server_client_connected")
		UIUtils.safe_connect(rust_core.on_server_client_disconnected, _on_client_disconnected, "ServerMain on_server_client_disconnected")

		rust_core.start_backend(port)

		print("[SERVER] Listening for clients on port %d" % port)
	else:
		print("[SERVER] Offline mode enabled. Skipping network initialization.")

func _on_client_connected(client_id: int) -> void:
	print("[SERVER] Client Connected. Socket ID: ", client_id)
	# The client socket is open, but we wait to process them in the ECS
	# until they send their AuthRequest containing their username.

func _on_client_disconnected(client_id: int) -> void:
	print("[SERVER] Client Disconnected. Socket ID: ", client_id)

	var player_entity := EntityMap.server.get_entity(client_id)
	if not player_entity: return

	# TODO: Fetch their Zone ID, XYZ coordinates, and Health and save it to the Turso Database here!

	var world := GameOrchestrator.server_world
	if not world: return

	# Tell all other clients that this player left
	var all_clients := EntityMap.server.get_all_active_clients()
	var writer := StreamPeerBuffer.new()
	writer.put_64(client_id)
	NetworkRouter.server.queue_broadcast(all_clients, OpCode.ID.ENTITY_DESPAWN, writer.data_array)

	world.remove_entity(player_entity)
	var node := player_entity as Node
	if node: node.queue_free()

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
