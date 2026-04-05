class_name ServerMovementNetworkSystem extends System

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	# Read specifically from the SERVER namespace
	var buckets:= NetworkRouter.server.incoming_buckets
	if buckets.is_empty(): return

	if buckets.has(OpCode.ID.INPUT_TICK):
		_process_input_ticks(buckets[OpCode.ID.INPUT_TICK])

func _process_input_ticks(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		var client_id := ids[i]

		# O(1) Lookup using the SERVER EntityMap
		var player_entity := EntityMap.server.get_entity(client_id)
		if not player_entity: continue

		reader.seek(offsets[i])
		var dir_x := reader.get_float()
		var dir_y := reader.get_float()

		var input_comp := player_entity.get_component(C_MoveInput) as C_MoveInput
		if input_comp:
			input_comp.dir = Vector2(dir_x, dir_y)
