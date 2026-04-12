class_name ServerInventoryActionSystem extends System

func query() -> QueryBuilder:
	# Example: A player requested to bury a bone (Action ID 2)
	return q.with_all([C_ActionRequest, C_PlayerTag])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var request = entity.get_component(C_ActionRequest) as C_ActionRequest
		
		if request.action_id == 2: # Bury Item
			_bury_bone(entity, request.target_id)
			
		cmd.remove_component(entity, C_ActionRequest)

func _bury_bone(player: Entity, item_id: int) -> void:
	# Check if they actually have the bone
	var has_item = false
	var relationship_to_remove: Relationship = null
	
	for rel in player.get_relationships():
		if rel.target and rel.target.has_component(C_Interactable):
			var interact = rel.target.get_component(C_Interactable) as C_Interactable
			if interact.item_id == item_id:
				has_item = true
				relationship_to_remove = rel
				break
				
	if has_item:
		cmd.remove_relationship(player, relationship_to_remove)
		# Grant something, play animation, etc.
		print("Player buried a bone!")
