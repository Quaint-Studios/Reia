class_name ServerCombatNetworkSystem extends System

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	# Vital: Ensure this runs even if there are no combat entities actively engaged
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	# Read specifically from the SERVER namespace
	var buckets := NetworkRouter.server.incoming_buckets
	if buckets.is_empty(): return

	if buckets.has(OpCode.ID.CAST_SKILL):
		_process_skill_casts(buckets[OpCode.ID.CAST_SKILL])

func _process_skill_casts(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		var client_id := ids[i]

		# Who cast the spell?
		var actor := EntityMap.server.get_entity(client_id)
		if not actor: continue

		reader.seek(offsets[i])
		var target_net_id := reader.get_64()
		var skill_id := reader.get_u16()

		# Who are they aiming at?
		var target := EntityMap.server.get_entity(target_net_id)
		if target and not target.has_component(C_Dead):
			# Queue the intent for the execution systems to handle later in the frame
			cmd.add_component(actor, C_CastRequest.new(skill_id, target))
