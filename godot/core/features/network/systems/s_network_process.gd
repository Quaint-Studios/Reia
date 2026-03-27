class_name NetworkProcessSystem extends System

## Iterates over the globally cached FFI packets and translates them into ECS data.
## TODO: Needs work. Right now it's just a stub to demonstrate the concept of an
## ECS system consuming the NetworkRouter's inbox. We might need to cache all players
## in a dictionary for O(1) access when processing packets, etc. The question is...
## how do we access their components efficiently since get_component() will slow things
## down.

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var count := NetworkRouter.in_ops.size()
	if count == 0: return

	for i in range(count):
		var client_id := NetworkRouter.in_client_ids[i]
		var op_code := NetworkRouter.in_ops[i]
		var payload := NetworkRouter.in_payloads[i]

		match op_code:
			OpCode.ID.AUTH_REQUEST:
				_handle_auth_request(client_id, payload)
			OpCode.ID.INPUT_TICK:
				_handle_input_tick(client_id, payload)
			# TODO: ... handle other specific op_codes natively in GDScript ...
			_:
				push_warning("Unhandled OpCode in NetworkProcessSystem: %d" % op_code)

	# CRITICAL: Clear the inbox once processed so we don't process them again next frame!
	NetworkRouter.clear_inbox()

func _handle_auth_request(_client_id: int, _payload: PackedByteArray) -> void:
	# Deserialize payload, create C_PlayerTag entity, etc.
	# TODO: Implement
	pass

func _handle_input_tick(_client_id: int, _payload: PackedByteArray) -> void:
	# Deserialize rkyv movement bytes, apply to C_Velocity
	# TODO: Implement
	pass
