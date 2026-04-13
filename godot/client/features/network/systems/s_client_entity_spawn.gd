class_name ClientEntitySpawnSystem extends System
## Listens for ENTITY_SPAWN and dynamically generates the visual Godot Nodes for players and items

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var buckets := NetworkRouter.client.incoming_buckets
	if buckets.has(OpCode.ID.ENTITY_SPAWN):
		_process_spawns(buckets[OpCode.ID.ENTITY_SPAWN])

func _process_spawns(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		reader.seek(offsets[i])
		var net_id := reader.get_64()
		var entity_type := reader.get_string()
		var entity_name := reader.get_string()
		var tx := reader.get_float()
		var ty := reader.get_float()
		var tz := reader.get_float()

		if EntityMap.client.get_entity(net_id): continue

		var entity := Entity.new()
		entity.add_component(C_NetworkId.new(net_id))
		entity.add_component(C_MovementSync.new(Transform3D(Basis(), Vector3(tx, ty, tz))))

		if net_id == GameOrchestrator.local_client_net_id:
			entity.add_component(C_LocalPlayer.new())
			
			var cam := Camera3D.new()
			cam.position = Vector3(0, 2, 4)
			cam.current = true
			cam.set_script(preload("res://client/features/player/client_player_interact.gd"))
			entity.add_child(cam)
			
			var input_node := Node.new()
			input_node.set_script(preload("res://core/features/combat/player_input.gd"))
			input_node.set("local_player_entity", entity)
			entity.add_child(input_node)

		if entity_type == "PLAYER":
			entity.add_component(C_Username.new(entity_name))
			
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = CapsuleMesh.new()
			entity.add_child(mesh_instance)

		elif entity_type == "BONE":
			entity.add_component(C_Interactable.new(entity_name, ActionVerb.ID.PICKUP, OpCode.ID.PICKUP_ITEM))
			
			var mesh_instance := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.2, 0.1, 0.6)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("#E3DAC9")
			box.material = mat
			mesh_instance.mesh = box
			
			var static_body := StaticBody3D.new()
			var col := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = box.size
			col.shape = shape
			
			static_body.add_child(col)
			static_body.collision_layer = 0
			static_body.set_collision_layer_value(14, true)
			
			entity.add_child(mesh_instance)
			entity.add_child(static_body)

		get_tree().current_scene.add_child(entity)
		cmd.add_entity(entity)
