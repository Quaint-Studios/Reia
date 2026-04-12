class_name ServerNetworkDispatcherSystem extends System

var reader := StreamPeerBuffer.new()
var _handlers: Dictionary[int, Callable] = {}

func setup() -> void:
	# Register O(1) OpCode handlers here
	_handlers[OpCode.ID.ACTION_REQUEST] = _handle_action_request
	_handlers[OpCode.ID.CAST_SKILL] = _handle_cast_skill
	_handlers[OpCode.ID.INPUT_TICK] = _handle_input_tick

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var buckets := NetworkRouter.server.incoming_buckets
	if buckets.is_empty(): return
	
	# Iterate through received OpCodes and execute their mapped Callables without branching
	for op_code in buckets.keys():
		var handler := _handlers.get(op_code, Callable())
		if handler.is_valid():
			handler.call(buckets[op_code])
		else:
			push_warning("[NetworkDispatcher] No handler registered for OpCode: %d" % op_code)

# ==========================================
# PACKET DESERIALIZERS
# ==========================================

func _handle_action_request(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		var actor := EntityMap.server.get_entity(ids[i])
		if not actor: continue

		reader.seek(offsets[i])
		var action_id := reader.get_u32()
		var target_net_id := reader.get_64()

		var target := EntityMap.server.get_entity(target_net_id)
		
		# O(1) Magic: We look up the component script based on the network integer 
		# and attach it to the actor dynamically!
		var component_script := ActionVerbRegistry.get_component_script(action_id)
		if component_script:
			cmd.add_component(actor, component_script.new(target))
		else:
			push_warning("Unknown Action Verb ID: %d" % action_id)

func _handle_cast_skill(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		var actor := EntityMap.server.get_entity(ids[i])
		if not actor: continue

		reader.seek(offsets[i])
		var target_net_id := reader.get_64()
		var skill_id := reader.get_u16()

		var target := EntityMap.server.get_entity(target_net_id)
		if target and not target.has_component(C_Dead):
			cmd.add_component(actor, C_CastRequest.new(skill_id, target))

func _handle_input_tick(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		var actor := EntityMap.server.get_entity(ids[i])
		if not actor: continue

		reader.seek(offsets[i])
		var dir_x := reader.get_float()
		var dir_y := reader.get_float()

		var input_comp := actor.get_component(C_MoveInput) as C_MoveInput
		if input_comp:
			input_comp.dir = Vector2(dir_x, dir_y)
