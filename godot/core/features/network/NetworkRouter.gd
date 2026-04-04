extends Node
## AUTOLOAD: NetworkRouter

@onready var rust_core: RustCore = get_node_or_null("/root/ServerMain/RustCore")

## Setting this to true will bypass Rust
var offline_mode: bool = false

# --- THE INBOX (Received from Rust) ---
# Format: { OpCode (int): { "ids": PackedInt64Array, "data": PackedByteArray, "offsets": PackedInt32Array } }
var incoming_buckets: Dictionary[int, Dictionary] = {}

# --- THE OUTBOX ---
var out_targets: PackedInt64Array = PackedInt64Array()
var out_ops: PackedInt32Array = PackedInt32Array()
var out_data: PackedByteArray = PackedByteArray()
var out_offsets: PackedInt32Array = PackedInt32Array()

func _ready() -> void:
	if not rust_core:
		rust_core = get_node_or_null("/root/ServerMain/RustCore")

	if rust_core:
		UIUtils.safe_connect(
			rust_core.on_network_events,
			_on_rust_packets,
			"NetworkRouter rust_core.on_network_event"
		)

# ==========================================
# INBOX HANDLING
# ==========================================

func _on_rust_packets(buckets: Dictionary) -> void:
	incoming_buckets = buckets

func clear_inbox() -> void:
	incoming_buckets.clear()

# ==========================================
# OUTBOX HANDLING
# ==========================================

## Sends a unique packet to a specific client
func queue_packet(target_id: int, op_code: int, payload: PackedByteArray) -> void:
	var target_success := out_targets.push_back(target_id)
	if not target_success:
		push_error("[NetworkRouter] Failed to queue target_id: %d" % target_id)
		return
	var op_success := out_ops.push_back(op_code)
	if not op_success:
		push_error("[NetworkRouter] Failed to queue op_code: %d" % op_code)
		return
	var offset_success := out_offsets.push_back(out_data.size())
	if not offset_success:
		push_error("[NetworkRouter] Failed to queue offset for op_code: %d" % op_code)
		return
	out_data.append_array(payload)


func broadcast(target_ids: PackedInt64Array, op_code: int, payload: PackedByteArray) -> void:
	if offline_mode:
		# In offline mode, a broadcast acts just like a targeted queue for the local player
		for id in target_ids:
			queue_packet(id, op_code, payload)
	elif rust_core:
		rust_core.broadcast_packet(target_ids, op_code, payload)

## MUST BE CALLED at the very end of ServerMain / ClientMain _physics_process()
func flush_outbox() -> void:
	if out_targets.is_empty(): return

	if offline_mode:
		_simulate_local_loopback()
	elif rust_core:
		rust_core.send_packets_batched(out_targets, out_ops, out_data, out_offsets)

	# Force Godot to drop the old memory buffers
	out_targets = PackedInt64Array()
	out_ops = PackedInt32Array()
	out_data = PackedByteArray()
	out_offsets = PackedInt32Array()

## Parses the Outbox and dumps it directly into the Inbox for Solo Play
func _simulate_local_loopback() -> void:
	for i in range(out_ops.size()):
		var op := out_ops[i]
		var target := out_targets[i]
		var start := out_offsets[i]
		var end := out_offsets[i + 1] if i + 1 < out_offsets.size() else out_data.size()
		var payload := out_data.slice(start, end)

		if not incoming_buckets.has(op):
			incoming_buckets[op] = {
				"ids": PackedInt64Array(),
				"data": PackedByteArray(),
				"offsets": PackedInt32Array()
			}

		var bucket := incoming_buckets[op]

		@warning_ignore("unsafe_cast")
		var offset_success := (bucket["offsets"] as PackedInt32Array).push_back((bucket["data"] as PackedByteArray).size())
		if not offset_success:
			push_error("[NetworkRouter] Failed to queue offset for op_code: %d" % op)
		@warning_ignore("unsafe_cast")
		var id_success := (bucket["ids"] as PackedInt64Array).push_back(target)
		if not id_success:
			push_error("[NetworkRouter] Failed to queue target_id for op_code: %d" % op)
		@warning_ignore("unsafe_cast")
		(bucket["data"] as PackedByteArray).append_array(payload)
