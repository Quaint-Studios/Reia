extends Node
## AUTOLOAD: NetworkRouter
## The global I/O cache. Divided into Server and Client namespaces.

## Setting this to true will bypass Rust
var offline_mode: bool = false

class NetworkChannel extends RefCounted:
	# --- THE INBOX (Received from Rust) ---
	# Format: { OpCode (int): { "ids": PackedInt64Array, "data": PackedByteArray, "offsets": PackedInt32Array } }
	var incoming_buckets: Dictionary[int, Dictionary] = {}

	# --- THE OUTBOX ---
	var out_targets: PackedInt64Array = PackedInt64Array()
	var out_ops: PackedInt32Array = PackedInt32Array()
	var out_data: PackedByteArray = PackedByteArray()
	var out_offsets: PackedInt32Array = PackedInt32Array()

	# --- OUTBOX (Broadcast Packets) ---
	var out_b_targets: PackedInt64Array = PackedInt64Array()
	var out_b_target_offsets: PackedInt32Array = PackedInt32Array()

	var out_b_ops: PackedInt32Array = PackedInt32Array()
	var out_b_data: PackedByteArray = PackedByteArray()
	var out_b_data_offsets: PackedInt32Array = PackedInt32Array()

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

	## Broadcasts the exact same payload to an array of clients
	func queue_broadcast(target_ids: PackedInt64Array, op_code: int, payload: PackedByteArray) -> void:
		# Track where the targets for this specific broadcast begin
		var target_offsets_success := out_b_target_offsets.push_back(out_b_targets.size())
		if not target_offsets_success:
			push_error("[NetworkRouter] Failed to queue broadcast target offset for op_code: %d" % op_code)
			return
		out_b_targets.append_array(target_ids)

		# Track the data and opcode
		var ops_success := out_b_ops.push_back(op_code)
		if not ops_success:
			push_error("[NetworkRouter] Failed to queue broadcast op_code: %d" % op_code)
			return
		var data_offsets_success := out_b_data_offsets.push_back(out_b_data.size())
		if not data_offsets_success:
			push_error("[NetworkRouter] Failed to queue broadcast offset for op_code: %d" % op_code)
			return
		out_b_data.append_array(payload)

	## Flushes all pending outbox data to the Rust network thread natively
	func flush_to_rust(rust_core: RustCore) -> void:
		if not rust_core: return

		# Flush Targeted Packets
		if not out_targets.is_empty():
			rust_core.send_packets_batched(
				out_targets,
				out_ops,
				out_data,
				out_offsets
			)

		# Flush Broadcast Packets (Batched FFI Call)
		if not out_b_targets.is_empty():
			rust_core.broadcast_packets_batched(
				out_b_targets,
				out_b_target_offsets,
				out_b_ops,
				out_b_data,
				out_b_data_offsets
			)

		reset_outbox()

	func clear_inbox() -> void:
		incoming_buckets.clear()

	func reset_outbox() -> void:
		out_targets = PackedInt64Array()
		out_ops = PackedInt32Array()
		out_data = PackedByteArray()
		out_offsets = PackedInt32Array()

		out_b_targets = PackedInt64Array()
		out_b_target_offsets = PackedInt32Array()
		out_b_ops = PackedInt32Array()
		out_b_data = PackedByteArray()
		out_b_data_offsets = PackedInt32Array()

# ==========================================
# INSTANTIATED CHANNELS
# ==========================================

var server := NetworkChannel.new()
var client := NetworkChannel.new()

func clear_all() -> void:
	server.clear_inbox()
	server.reset_outbox()
	client.clear_inbox()
	client.reset_outbox()
