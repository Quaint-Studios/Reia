class_name ClientEntityDespawnSystem extends System
## Listens for ENTITY_DESPAWN and cleans up visual nodes and ECS entities on clients

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var despawn_bucket := NetworkRouter.client.consume_bucket(OpCode.ID.ENTITY_DESPAWN)
	if not despawn_bucket.is_empty():
		_process_despawns(despawn_bucket)

func _process_despawns(bucket: Dictionary) -> void:
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(offsets.size()):
		reader.seek(offsets[i])
		var net_id := reader.get_64()

		var entity := EntityMap.client.get_entity(net_id)
		if not entity: continue

		var vis_comp := entity.get_component(C_VisualNode) as C_VisualNode
		if vis_comp and is_instance_valid(vis_comp.node):
			vis_comp.node.queue_free()

		var world := GameOrchestrator.client_world
		if world:
			world.remove_entity(entity)
