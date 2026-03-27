extends Node
## AUTOLOAD: NetworkRouter

@onready var rust_core: RustCore = get_node_or_null("/root/ServerMain/RustCore")

# --- THE INBOX (Received from Rust) ---
var in_client_ids: PackedInt64Array = PackedInt64Array()
var in_ops: PackedInt32Array = PackedInt32Array()
var in_payloads: Array[PackedByteArray] = []

# --- THE OUTBOX ---
var out_targets: PackedInt64Array = PackedInt64Array()
var out_ops: PackedInt32Array = PackedInt32Array()
var out_payloads: Array[PackedByteArray] = []

func _ready() -> void:
	# If not on server, try looking for the ClientMain node
	if not rust_core:
		rust_core = get_node_or_null("/root/ClientMain/MmoCore")

	if rust_core:
		UIUtils.safe_connect(
			rust_core.on_network_events,
			_on_rust_packets_batched,
			"NetworkRouter rust_core.on_network_event"
		)

# ==========================================
# INBOX HANDLING
# ==========================================

func _on_rust_packets_batched(c_ids: PackedInt64Array, ops: PackedInt32Array, pays: Array) -> void:
	# Instantly merge the batched arrays received from the Rust FFI signal
	in_client_ids.append_array(c_ids)
	in_ops.append_array(ops)
	in_payloads.append_array(pays)

func clear_inbox() -> void:
	in_client_ids.clear()
	in_ops.clear()
	in_payloads.clear()

# ==========================================
# OUTBOX HANDLING
# ==========================================

## Global helper for GDScript to queue packets for sending
func queue_packet(target_id: int, op_code: int, payload: PackedByteArray) -> void:
	var targets_success := out_targets.push_back(target_id)
	if not targets_success:
		push_error("[NetworkRouter] Failed to queue target_id: %d" % target_id)
	var ops_success := out_ops.push_back(op_code)
	if not ops_success:
		push_error("[NetworkRouter] Failed to queue op_code: %d" % op_code)
	out_payloads.append(payload)

## MUST BE CALLED at the very end of ServerMain / ClientMain _physics_process()
func flush_outbox() -> void:
	if rust_core and not out_targets.is_empty():
		# Crosses the FFI boundary exactly once with thousands of packets
		rust_core.send_packets_batched(out_targets, out_ops, out_payloads)

		# Reset the outbox for the next frame
		out_targets.clear()
		out_ops.clear()
		out_payloads.clear()
