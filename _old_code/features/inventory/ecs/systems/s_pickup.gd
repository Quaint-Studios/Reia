class_name PickupSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Player, C_PickupRequest]) # TODO: .iterate() for more efficiency in the future

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for player in entities:
		var req := player.get_component(C_PickupRequest) as C_PickupRequest
		if req.item_entity_id == -1:
			player.remove_component(C_PickupRequest)
			continue

		var item := instance_from_id(req.item_entity_id) as Entity
		if item == null or not item.has_component(C_Item) or not item.has_component(C_OnGround):
			player.remove_component(C_PickupRequest)
			continue

		var inv := _get_inventory(player)
		if inv == null:
			player.remove_component(C_PickupRequest)
			continue

		# Capacity: adding an item creates a relationship slot (even stackables remain 1 slot per unique stack entry)
		if not InventoryRelation.can_add_slots(inv, 1):
			player.remove_component(C_PickupRequest)
			continue

		# Remove ground marker
		item.remove_component(C_OnGround)

		# Contain item
		# Non-stackable items: relationship count=1
		# Stackable items: we still add relationship count=stack.count; you can also merge (see InventoryAddSystem below)
		var rel := InventoryRelation.contains_item(item, 1)
		inv.add_relationship(rel)

		player.remove_component(C_PickupRequest)

func _get_inventory(player: Entity) -> Entity:
	var rels := player.get_relationships(InventoryRelation.owns_inventory(null))
	if rels.is_empty():
		return null
	return rels[0].target # as Entity
