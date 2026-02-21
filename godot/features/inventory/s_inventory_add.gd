class_name InventoryAddSystem
extends System

func query() -> QueryBuilder:
	# inventory entities that received add requests via relationship or component
	return q.with_all([C_Inventory, C_InventoryAddRequest])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for inv in entities:
		var req := inv.get_component(C_InventoryAddRequest) as C_InventoryAddRequest
		if req.item_entity_id == -1 or req.count <= 0:
			inv.remove_component(C_InventoryAddRequest)
			continue

		var item := instance_from_id(req.item_entity_id) as Entity
		if item == null or not item.has_component(C_Item):
			inv.remove_component(C_InventoryAddRequest)
			continue

		# If item is stackable, merge into existing stack of same "item prototype".
		# For production: you usually have a stable "item_def_id" (not unique_id) to compare.
		# Here we approximate by name+category+grade for the example.
		var stack := item.get_component(C_ItemStack) as C_ItemStack
		if stack != null and stack.is_stackable:
			var to_add := mini(req.count, stack.count)

			var merged := _try_merge_stack(inv, item, to_add)
			if merged:
				# We consumed the incoming stack units; item entity can be destroyed or reduced.
				stack.count -= to_add
				if stack.count <= 0:
					ECS.world.remove_entity(item)

				inv.remove_component(C_InventoryAddRequest)
				continue

		# Non-stackable OR couldn't merge: add as a new contained item slot
		if not InventoryRelation.can_add_slots(inv, 1):
			inv.remove_component(C_InventoryAddRequest)
			continue

		inv.add_relationship(InventoryRelation.contains_item(item, 1))
		inv.remove_component(C_InventoryAddRequest)

func _try_merge_stack(inv: Entity, incoming_item: Entity, add_count: int) -> bool:
	var in_item := incoming_item.get_component(C_Item) as C_Item
	# Search existing contained items (relationship targets)
	var rels := inv.get_relationships(InventoryRelation.any_contains_item())
	for rel in rels:
		var existing_item : Entity = rel.target # as Entity
		if existing_item == null:
			continue
		if not existing_item.has_component(C_ItemStack):
			continue

		var ex_item := existing_item.get_component(C_Item) as C_Item
		var ex_stack := existing_item.get_component(C_ItemStack) as C_ItemStack

		if not ex_stack.is_stackable:
			continue

		# “Same stack type” rule (replace with item_def_id later)
		if ex_item.category != in_item.category:
			continue
		if ex_item.name != in_item.name:
			continue
		if ex_item.grade != in_item.grade:
			continue

		var space := ex_stack.max_stack - ex_stack.count
		if space <= 0:
			continue

		var actual := mini(space, add_count)
		ex_stack.count += actual
		return true

	return false
