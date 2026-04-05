class_name ServerStateSyncSystem extends System

var writer := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	# We only care about entities that have moved (we would tag them with C_NetworkSyncDirty in Physics)
	return q.with_all([C_Transform, C_NetworkSyncDirty])

func process(entities: Array[Entity], components: Array, _delta: float) -> void:
	if entities.is_empty(): return

	var transforms: Array[Component] = components[0]
	writer.clear()

	# Header: How many entities are updating?
	writer.put_u32(entities.size())

	# Payload: Pack the state
	for i in range(entities.size()):
		var entity := entities[i]
		var trans := transforms[i] as C_Transform
		var pos := trans.transform.origin

		# Get the network ID (Positive for players, Negative for monsters)
		writer.put_64(EntityMap.server.get_network_id(entity))
		writer.put_float(pos.x)
		writer.put_float(pos.y)
		writer.put_float(pos.z)

		# Remove the dirty flag so we don't sync them again next frame unless they move
		cmd.remove_component(entity, C_NetworkSyncDirty)

	# 3. Broadcast to all clients!
	# In a real MMO, you filter 'target_ids' to only include clients in the same Chunk.
	# For now, we broadcast to everyone (ID 0 in some setups, or pass an array of all connected clients)
	var all_connected_clients: PackedInt64Array = _get_all_active_clients()

	NetworkRouter.server.queue_broadcast(all_connected_clients, OpCode.ID.STATE_SYNC, writer.data_array)

func _get_all_active_clients() -> PackedInt64Array:
	# Logic to return all active keys from EntityMap.server._net_id_to_entity where ID > 0
	var ids: PackedInt64Array = PackedInt64Array()
	# ... extraction logic ...
	return ids
