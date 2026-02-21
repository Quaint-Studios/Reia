class_name DropSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_DropRequest])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for actor in entities:
		var req := actor.get_component(C_DropRequest) as C_DropRequest
		if req == null or req.item_entity_id == -1:
			actor.remove_component(C_DropRequest)
			continue

		var item := instance_from_id(req.item_entity_id) as Entity
		if item == null or not item.has_component(C_Item):
			actor.remove_component(C_DropRequest)
			continue

		# Find actor inventory (relationship)
		var inv := InventoryRelation.get_inventory_of_player(actor)
		if inv == null:
			actor.remove_component(C_DropRequest)
			continue

		# Ensure item is in inventory
		var containment := InventoryRelation.find_containment_relationship(inv, item)
		if containment == null:
			actor.remove_component(C_DropRequest)
			continue

		# Handle stack split
		var stack := item.get_component(C_ItemStack) as C_ItemStack
		var drop_count := maxi(1, req.count)

		if stack != null and stack.is_stackable and stack.count > 1 and drop_count < stack.count:
			# Split: create a new item entity on ground with drop_count,
			# and reduce original stack in inventory.
			var new_item := _clone_item_entity(item)
			var new_stack := new_item.get_component(C_ItemStack) as C_ItemStack
			new_stack.count = drop_count

			stack.count -= drop_count

			new_item.add_component(C_OnGround.new())
			_set_entity_transform(new_item, req.drop_transform)

			# Add new entity to world safely
			ECS.world.add_entity(new_item)

			# Note: original remains in inventory, so we do NOT remove containment relationship.
			actor.remove_component(C_DropRequest)
			continue

		# Drop whole item entity (non-stackable or full stack)
		inv.remove_relationship(containment)
		if not item.has_component(C_OnGround):
			item.add_component(C_OnGround.new())
		_set_entity_transform(item, req.drop_transform)

		actor.remove_component(C_DropRequest)

func _set_entity_transform(entity: Entity, t: Transform3D) -> void:
	# Here we set Node3D transform directly for demo purposes.
	ECSUtils.update_transform3d(entity, t);

func _clone_item_entity(src_item: Entity) -> Entity:
	# Minimal "entity clone" for item data.
	# For production: prefer spawning from an item prefab/definition.
	var e := Entity.new()

	# Copy C_Item
	var src_c_item := src_item.get_component(C_Item) as C_Item
	var c_item := C_Item.new()
	c_item.unique_id = 0 # new instance; DB id would be generated server-side
	c_item.name = src_c_item.name
	c_item.description = src_c_item.description
	c_item.category = src_c_item.category
	c_item.grade = src_c_item.grade
	e.add_component(c_item)

	# Copy stack component if present
	var src_stack := src_item.get_component(C_ItemStack) as C_ItemStack
	if src_stack != null:
		var c_stack := C_ItemStack.new()
		c_stack.is_stackable = src_stack.is_stackable
		c_stack.count = src_stack.count
		c_stack.max_stack = src_stack.max_stack
		e.add_component(c_stack)

	return e
