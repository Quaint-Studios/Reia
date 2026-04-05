class_name ClientMain extends Node

## The Root Node for the Client Presentation Layer.
## Responsible for connecting to the server, registering visual Observers,
## and ticking the Client-side prediction ECS.

var ip: String
var port: int
var is_offline: bool
var rust_core: RustCore

func _init(_ip: String, _port: int, _offline: bool = false) -> void:
	ip = _ip
	port = _port
	is_offline = _offline
	name = "ClientMain"

func _ready() -> void:
	# Create GECS World
	var world := World.new()
	world.name = "ClientWorld"
	GameOrchestrator.client_world = world

	# Builds prediction systems and visual observers instantly
	ClientPipeline.build(world)


	if not is_offline:
		print("[CLIENT] Starting Client Initialization...")

		# Start client
		rust_core = RustCore.new()
		add_child(rust_core)
		UIUtils.safe_connect(rust_core.on_network_events, _on_rust_packets, "ClientMain on_network_events")
		rust_core.start_client(ip, port)

		print("[CLIENT] Connecting to server at %s:%d..." % [ip, port])
	else:
		print("[CLIENT] Offline mode enabled. Skipping network initialization.")
		print("[CLIENT] Routing to Title Screen...")

	# Create GECS World
	world.name = "ClientWorld"
	add_child(world)
	ECS.world = world

	# Builds prediction systems and visual observers instantly
	ClientPipeline.build(ECS.world)

	print("[CLIENT] Network, ECS & Observers Initialized. Routing to Title Screen...")

func _on_rust_packets(buckets: Dictionary) -> void:
	NetworkRouter.client.incoming_buckets = buckets

func _physics_process(delta: float) -> void:
	# Exact same loop as the server, but Client systems only do
	# prediction, interpolation, and VFX triggering.
	if rust_core: rust_core.poll_network()

	var world := GameOrchestrator.client_world

	world.process(delta, SystemGroups.PRE_PROCESS)

	# TODO: CommandBuffer

	# Safely flush to the Rust network thread
	NetworkRouter.client.flush_to_rust(rust_core)
	NetworkRouter.client.clear_inbox()
