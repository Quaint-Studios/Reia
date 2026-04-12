class_name ServerInventoryNetworkSystem extends System

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var buckets := NetworkRouter.server.incoming_buckets
	if buckets.is_empty(): return
	
	# Process all inventory-domain OpCodes
	if buckets.has(OpCode.ID.PICKUP_ITEM):
		_process_pickup(buckets[OpCode.ID.PICKUP_ITEM])
		
	if buckets.has(OpCode.ID.BURY_ITEM):
		_process_bury(buckets[OpCode.ID.BURY_ITEM])

func _process_pickup(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		var player := EntityMap.server.get_entity(ids[i])
		if not player: continue

		reader.seek(offsets[i])
		var target_net_id := reader.get_64()
		var target_item := EntityMap.server.get_entity(target_net_id)
		
		if target_item and target_item.has_component(C_Transform):
			var p_pos := (player.get_component(C_Transform) as C_Transform).transform.origin
			var i_pos := (target_item.get_component(C_Transform) as C_Transform).transform.origin
			
			# Fast spatial validation
			if p_pos.distance_to(i_pos) <= 3.0:
				_execute_pickup(player, target_item)

func _execute_pickup(player: Entity, item: Entity) -> void:
	print("Player picked up an item!")
	var interactable := item.get_component(C_Interactable) as C_Interactable
	
	# Clone the item data to store in the player's relationship inventory
	var item_data := C_Interactable.new(interactable.item_name, interactable.action_verb, interactable.interact_op_code)
	cmd.add_relationship(player, Relationship.new(C_HasItem.new(1), item_data))
	
	# Despawn the physical item from the world
	cmd.remove_entity(item)
	var node := item as Node
	if node: node.queue_free()

func _process_bury(_bucket: Dictionary) -> void:
	# Logic for finding the item in the relationship array and removing it
	print("Player wants to bury an item, but this is not implemented yet!")
