class_name InventoryExecutionSystem extends System

func query() -> QueryBuilder:
	# Only process requests that survived the Validator pipeline without getting blocked
	return q.with_all([C_ItemTransferRequest]).with_none([C_InventoryActionBlocked])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var request := entity.get_component(C_ItemTransferRequest) as C_ItemTransferRequest
		
		# Logic to move the relationship (item) from Source to Target inventory
		request.source_inventory.remove_relationship(request.item_relationship)
		request.target_inventory.add_relationship(request.item_relationship)
		
		# Clean up the request component once processed
		cmd.remove_component(entity, C_ItemTransferRequest)
