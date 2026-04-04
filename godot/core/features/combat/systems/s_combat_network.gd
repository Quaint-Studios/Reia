class_name CombatNetworkSystem extends System

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var buckets := NetworkRouter.incoming_buckets
	if buckets.is_empty(): return
	
	# Group all Combat-related OpCodes in this file!
	if buckets.has(OpCode.ID.CAST_SKILL):
		_process_skill_casts(buckets[OpCode.ID.CAST_SKILL])
		
	if buckets.has(OpCode.ID.CANCEL_SKILL):
		_process_skill_cancels(buckets[OpCode.ID.CANCEL_SKILL])

func _process_skill_casts(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]
	
	for i in range(ids.size()):
		var actor_entity := EntityMap.get_entity(ids[i])
		if not actor_entity: continue
		
		reader.seek(offsets[i])
		var target_net_id := reader.get_64()
		var skill_id := reader.get_u16()
		
		var target_entity := EntityMap.get_entity(target_net_id)
		if target_entity and not target_entity.has_component(C_Dead):
			# SAFE: We are using our own native System Command Buffer
			cmd.add_component(actor_entity, C_CastRequest.new(skill_id, target_entity))

func _process_skill_cancels(_bucket: Dictionary) -> void:
	# Logic to handle interrupting a channel...
	pass
