class_name BankAccessValidator extends System

func query():
	return q.with_all([C_InventoryOpenRequest, C_Transform]).with_none([C_InventoryActionBlocked])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	var bank_npcs := ECS.world.query.with_all([C_BankNPC, C_Transform]).execute()
	
	for entity in entities:
		var request := entity.get_component(C_InventoryOpenRequest) as C_InventoryOpenRequest
		if not request.target_inventory_entity.has_component(C_BankTag):
			continue
			
		var player_pos := (entity.get_component(C_Transform) as C_Transform).transform.origin
		var is_near := bank_npcs.any(func(npc: Entity) -> bool:
			return player_pos.distance_to((npc.get_component(C_Transform) as C_Transform).transform.origin) <= 5.0
		)
		
		if not is_near:
			cmd.add_component(entity, C_InventoryActionBlocked.new(InventoryErrors.TOO_FAR_FROM_BANK))
