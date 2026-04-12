extends Node
## AUTOLOAD: GameOrchestrator
## Manages the lifecycles of the Server and Client sessions.

const NetworkChannel = NetworkRouter.NetworkChannel

var active_server: ServerMain
var active_client: ClientMain

signal server_world_changed(world: World)
signal server_world_exited
signal client_world_changed(world: World)
signal client_world_exited

var server_world: World:
	get:
		return server_world
	set(value):
		# Add the new world to the scenes
		server_world = value
		if server_world:
			if not server_world.is_inside_tree():
				# Add the world to the tree if it is not already
				get_tree().root.add_child(server_world)
			if not server_world.tree_exited.is_connected(_on_server_world_exited):
				UIUtils.safe_connect(server_world.tree_exited, _on_server_world_exited, "GameOrchestrator _on_server_world_exited")
		server_world_changed.emit(server_world)
		assert(GECSEditorDebuggerMessages.set_world(server_world) if ECS.debug else true, 'Debug Data')
var client_world: World:
	get:
		return client_world
	set(value):
		# Add the new world to the scenes
		client_world = value
		if client_world:
			if not client_world.is_inside_tree():
				# Add the world to the tree if it is not already
				get_tree().root.add_child(client_world)
			if not client_world.tree_exited.is_connected(_on_client_world_exited):
				UIUtils.safe_connect(client_world.tree_exited, _on_client_world_exited, "GameOrchestrator tree_exited")
		client_world_changed.emit(client_world)
		assert(GECSEditorDebuggerMessages.set_world(client_world) if ECS.debug else true, 'Debug Data')

var is_offline_mode: bool = false

func _ready() -> void:
	# Listen to UI intents globally
	UIUtils.safe_connect(UIEventBus.session.intent_play_solo, _on_intent_play_solo, "GameOrchestrator intent_play_solo")
	UIUtils.safe_connect(UIEventBus.session.intent_host_and_play, _on_intent_host_and_play, "GameOrchestrator intent_host_and_play")
	UIUtils.safe_connect(UIEventBus.session.intent_play_online, _on_intent_play_online, "GameOrchestrator intent_play_online")
	UIUtils.safe_connect(UIEventBus.session.intent_host_only, _on_intent_host_only, "GameOrchestrator intent_host_only")

func _on_server_world_exited() -> void:
	server_world = null
	server_world_exited.emit()
	assert(GECSEditorDebuggerMessages.exit_world() if ECS.debug else true, 'Debug Data')

func _on_client_world_exited() -> void:
	client_world = null
	client_world_exited.emit()
	assert(GECSEditorDebuggerMessages.exit_world() if ECS.debug else true, 'Debug Data')

# ==========================================
# SESSION ROUTING
# ==========================================

func launch_dedicated_server(port: int) -> void:
	_teardown()
	print("[GameOrchestrator] Booting Dedicated Server on port %d" % port)
	is_offline_mode = false
	active_server = ServerMain.new(port)
	add_child(active_server)

func _on_intent_play_online(ip: String, port: int) -> void:
	_teardown()
	print("[GameOrchestrator] Booting Online Play (Connecting to Rust Server at %s:%d)" % [ip, port])
	is_offline_mode = false
	active_client = ClientMain.new(ip, port)
	add_child(active_client)

func _on_intent_play_solo() -> void:
	_teardown()
	print("[GameOrchestrator] Booting Offline Solo Mode (Bypassing Rust)")
	is_offline_mode = true

	# Boot both, but tell them not to start Rust networking
	active_server = ServerMain.new(7777, true)
	add_child(active_server)

	active_client = ClientMain.new("127.0.0.1", 7777, true)
	add_child(active_client)

func _on_intent_host_and_play(port: int) -> void:
	_teardown()
	print("[GameOrchestrator] Booting Host & Play (Local Rust Server)")
	is_offline_mode = false

	# Boot Server on the requested port
	active_server = ServerMain.new(port)
	add_child(active_server)

	# Boot Client connecting to localhost
	active_client = ClientMain.new("127.0.0.1", port)
	add_child(active_client)

func _on_intent_host_only(port: int) -> void:
	_teardown()
	print("[GameOrchestrator] Booting Host Only (Local Rust Server, No Client)")
	is_offline_mode = false

	# Boot Server on the requested port
	active_server = ServerMain.new(port)
	add_child(active_server)

# ==========================================
# OFFLINE LOOPBACK
# ==========================================

func _physics_process(_delta: float) -> void:
	# If we are offline, we manually move the data between the Client and Server
	# outboxes/inboxes natively in Godot, entirely bypassing the network stack.
	if is_offline_mode and active_server and active_client:
		_simulate_network_loopback(NetworkRouter.client, NetworkRouter.server)
		_simulate_network_loopback(NetworkRouter.server, NetworkRouter.client)

func _simulate_network_loopback(source: NetworkChannel, destination: NetworkChannel) -> void:
	# Loopback Targeted Packets
	for i in range(source.out_ops.size()):
		var op := source.out_ops[i]
		var target := source.out_targets[i]
		var start := source.out_offsets[i]
		var end := source.out_offsets[i + 1] if i + 1 < source.out_offsets.size() else source.out_data.size()
		var payload := source.out_data.slice(start, end)

		_push_to_inbox(destination, op, target, payload)

	# Loopback Broadcast Packets (Flattened Array Parsing)
	for i in range(source.out_b_ops.size()):
		var op := source.out_b_ops[i]

		# Slice Targets
		var t_start := source.out_b_target_offsets[i]
		var t_end := source.out_b_target_offsets[i + 1] if i + 1 < source.out_b_target_offsets.size() else source.out_b_targets.size()
		var targets := source.out_b_targets.slice(t_start, t_end)

		# Slice Payload Data
		var d_start := source.out_b_data_offsets[i]
		var d_end := source.out_b_data_offsets[i + 1] if i + 1 < source.out_b_data_offsets.size() else source.out_b_data.size()
		var payload := source.out_b_data.slice(d_start, d_end)

		for target in targets:
			_push_to_inbox(destination, op, target, payload)

	source.reset_outbox()

func _push_to_inbox(destination: NetworkRouter.NetworkChannel, op: int, target: int, payload: PackedByteArray) -> void:
	if not destination.incoming_buckets.has(op):
		destination.incoming_buckets[op] = {
			"ids": PackedInt64Array(),
			"data": PackedByteArray(),
			"offsets": PackedInt32Array()
		}

	var bucket := destination.incoming_buckets[op]
	@warning_ignore("unsafe_cast")
	var success_offsets := (bucket["offsets"] as PackedInt32Array).push_back((bucket["data"] as PackedByteArray).size())
	if not success_offsets:
		push_error("[GameOrchestrator] Failed to queue offset for op_code: %d" % op)
	@warning_ignore("unsafe_cast")
	var success_ids := (bucket["ids"] as PackedInt64Array).push_back(target)
	if not success_ids:
		push_error("[GameOrchestrator] Failed to queue id for op_code: %d" % op)
	@warning_ignore("unsafe_cast")
	(bucket["data"] as PackedByteArray).append_array(payload)

# ==========================================
# UTILITIES
# ==========================================

func _teardown() -> void:
	print("\nTearing down existing sessions and worlds...");
	if active_server:
		print("[GameOrchestrator] - Teardown: Removing Active Server")
		active_server.queue_free()
		active_server = null
	if active_client:
		print("[GameOrchestrator] - Teardown: Removing Active Client")
		active_client.queue_free()
		active_client = null
	server_world = null
	client_world = null
	NetworkRouter.clear_all()
	EntityMap.clear_all()
	print("[GameOrchestrator] Teardown complete.\n")
