class_name ServerAuthNetworkSystem extends System
## Listens for AUTH_REQUEST, spawns the player entity, and responds with AUTH_SUCCESS

var reader := StreamPeerBuffer.new()
var writer := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var buckets := NetworkRouter.server.incoming_buckets
	if buckets.has(OpCode.ID.AUTH_REQUEST):
		_process_auth(buckets[OpCode.ID.AUTH_REQUEST])

func _process_auth(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		var client_connection_id := ids[i]

		reader.seek(offsets[i])
		var username := reader.get_string()
		var _token := reader.get_string()

		# Generate a dummy Network ID
		var net_id := randi() % 1000000 + 1

		# Construct the logical Server Player Entity
		var player := Entity.new()
		player.add_component(C_NetworkId.new(net_id))
		player.add_component(C_Transform.new(Transform3D(Basis(), Vector3(0, 5, 0))))
		player.add_component(C_Velocity.new())
		player.add_component(C_MoveInput.new())
		player.add_component(C_CharacterBody3D.new())
		player.add_component(C_PlayerTag.new())
		player.add_component(C_Username.new(username))

		# Attach a physical collision body for movement tracking
		var body := CharacterBody3D.new()
		var col := CollisionShape3D.new()
		col.shape = CapsuleShape3D.new()
		body.add_child(col)
		player.add_child(body)

		get_tree().current_scene.add_child(player)
		cmd.add_entity(player)

		# Send Auth Success uniquely back to the joining Client
		writer.clear()
		writer.put_64(net_id)
		writer.put_u32(Zone.ID.WATERBROOK)
		NetworkRouter.server.queue_packet(client_connection_id, OpCode.ID.AUTH_SUCCESS, writer.data_array)

		# Broadcast the Entity Spawn so everyone can see the new player
		writer.clear()
		writer.put_64(net_id)
		writer.put_string("PLAYER")
		writer.put_string(username)
		writer.put_float(0.0) # X
		writer.put_float(5.0) # Y
		writer.put_float(0.0) # Z

		# TODO: Make sure to eventually query EntityMap for all clients in the zone. Using dummy 0 for loopback demo.
		var all_clients := PackedInt64Array([0])
		NetworkRouter.server.queue_broadcast(all_clients, OpCode.ID.ENTITY_SPAWN, writer.data_array)
