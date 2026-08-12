class_name ServerAuthNetworkSystem extends System
## Listens for AUTH_REQUEST, spawns the player entity, and responds with AUTH_SUCCESS

var reader := StreamPeerBuffer.new()
var writer := StreamPeerBuffer.new()

# TODO: Temporary for demo
var _has_spawned_dummy := false

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var auth_request_bucket := NetworkRouter.server.consume_bucket(OpCode.ID.AUTH_REQUEST)
	if not auth_request_bucket.is_empty():
		_process_auth(auth_request_bucket)

func _process_auth(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	# Store the network data for all players joining this frame
	var newly_joined_clients := []

	for i in range(ids.size()):
		var net_id := ids[i]

		reader.seek(offsets[i])
		var username := reader.get_string()
		var _token := reader.get_string()

		# Construct the logical Server Player Entity
		var player := Entity.new()

		# Attach a physical collision body for movement tracking
		var body := CharacterBody3D.new()
		var col := CollisionShape3D.new()
		col.shape = CapsuleShape3D.new()
		body.add_child(col)

		player.add_component(C_NetworkId.new(net_id))
		player.add_component(C_Transform.new(Transform3D(Basis(), Vector3(0, 5, 0))))
		player.add_component(C_Velocity.new())
		player.add_component(C_MoveInput.new())
		player.add_component(C_CharacterBody3D.new(body))
		player.add_component(C_PlayerTag.new())
		player.add_component(C_Username.new(username))

		player.add_child(body)

		cmd.add_entity(player)

		newly_joined_clients.append({
			"net_id": net_id,
			"username": username
		})

	# Queue the dummy if needed
	var spawn_dummy := false
	if not _has_spawned_dummy:
		_queue_test_dummy()
		_has_spawned_dummy = true
		spawn_dummy = true
	cmd.execute()
	var all_clients := EntityMap.server.get_all_active_clients() # TODO: Think of how to optimize this.
	for client: Dictionary in newly_joined_clients:
		var net_id: int = client["net_id"]
		var username: String = client["username"]
		# Send Auth Success uniquely back to the joining Client
		writer.clear()
		writer.put_64(net_id)
		writer.put_u32(Zone.ID.WATERBROOK)
		NetworkRouter.server.queue_packet(net_id, OpCode.ID.AUTH_SUCCESS, writer.data_array)

		# Send pre-existing entities to the joining client so they see everyone already online
		_send_existing_entities_to_client(net_id)

		# Broadcast the Entity Spawn so everyone can see the new player
		writer.clear()
		writer.put_64(net_id)
		writer.put_string("PLAYER")
		writer.put_string(username)
		writer.put_float(0.0) # X
		writer.put_float(5.0) # Y
		writer.put_float(0.0) # Z

		NetworkRouter.server.queue_broadcast(all_clients, OpCode.ID.ENTITY_SPAWN, writer.data_array)

	if spawn_dummy:
		_broadcast_test_dummy(all_clients)

func _queue_test_dummy() -> void:
	var dummy := Entity.new()
	var net_id := -1

	dummy.add_component(C_NetworkId.new(net_id))
	dummy.add_component(C_Transform.new(Transform3D(Basis(), Vector3(0, 1, -5))))
	dummy.add_component(C_Health.new(100, 100))
	dummy.add_component(C_MonsterTag.new())
	dummy.add_component(C_Username.new("Training Dummy"))

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	body.add_child(col)
	body.collision_layer = 0
	body.set_collision_layer_value(13, true)
	dummy.add_child(body)

	cmd.add_entity(dummy)

func _broadcast_test_dummy(all_clients: PackedInt64Array) -> void:
	writer.clear()
	writer.put_64(-1)
	writer.put_string("PLAYER") # TODO: This could be improved possibly by using an enum type
	writer.put_string("Training Dummy")
	writer.put_float(0.0)
	writer.put_float(1.0)
	writer.put_float(-5.0)

	NetworkRouter.server.queue_broadcast(all_clients, OpCode.ID.ENTITY_SPAWN, writer.data_array)
	print("[SERVER] Spawned Test Dummy.")

func _send_existing_entities_to_client(new_client_id: int) -> void:
	for existing_net_id: int in EntityMap.server._net_id_to_entity.keys():
		if existing_net_id == new_client_id:
			continue # Skip sending self, self is broadcasted separately

		var existing_entity := EntityMap.server.get_entity(existing_net_id)
		if not existing_entity: continue

		var username_comp := existing_entity.get_component(C_Username) as C_Username
		var entity_name := username_comp.username if username_comp else "Entity"
		var entity_type := "PLAYER" if existing_entity.get_component(C_PlayerTag) else "PLAYER"

		var trans_comp := existing_entity.get_component(C_Transform) as C_Transform
		var pos := trans_comp.transform.origin if trans_comp else Vector3.ZERO

		writer.clear()
		writer.put_64(existing_net_id)
		writer.put_string(entity_type)
		writer.put_string(entity_name)
		writer.put_float(pos.x)
		writer.put_float(pos.y)
		writer.put_float(pos.z)

		NetworkRouter.server.queue_packet(new_client_id, OpCode.ID.ENTITY_SPAWN, writer.data_array)
