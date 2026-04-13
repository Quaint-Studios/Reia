class_name ClientAuthNetworkSystem extends System
## Listens for AUTH_SUCCESS, stores the local ID, and fires the login UI event

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var buckets := NetworkRouter.client.incoming_buckets
	if buckets.has(OpCode.ID.AUTH_SUCCESS):
		_process_auth_success(buckets[OpCode.ID.AUTH_SUCCESS])

func _process_auth_success(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		reader.seek(offsets[i])
		var my_net_id := reader.get_64()
		var zone_id := reader.get_u32()

		# Store who WE are so the Spawner System knows which mesh gets the camera
		GameOrchestrator.local_client_net_id = my_net_id
		
		# Fire to the UI to drop the TitleScreen and load the map
		UIEventBus.auth.login_success.emit(zone_id)
		break # Only process Auth once per client
