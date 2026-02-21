class_name InventoryService
extends RefCounted

const GROUP_INVENTORY: String = "inventory"

class ItemView:
	var instance_id: int
	var name: String
	var description: String
	var category: int
	var grade: int
	var stackable: bool
	var count: int

	func _init(entity: Entity) -> void:
		instance_id = entity.get_instance_id()

		var c_item := entity.get_component(C_Item) as C_Item
		name = c_item.name
		description = c_item.description
		category = int(c_item.category)
		grade = int(c_item.grade)

		var c_stack := entity.get_component(C_ItemStack) as C_ItemStack
		stackable = (c_stack != null and c_stack.is_stackable)
		count = (c_stack.count if stackable else 1) if c_stack != null else 1

func get_local_player() -> Entity:
	if ECS.world == null:
		return null
	return ECS.world.query.with_all([C_LocalPlayer]).execute_one() as Entity

func get_inventory_of_player(player: Entity) -> Entity:
	if player == null:
		return null
	return InventoryRelation.get_inventory_of_player(player)

func ensure_player_inventory(player: Entity) -> Entity:
	if player == null or ECS.world == null:
		return null

	var inv := InventoryRelation.get_inventory_of_player(player)
	if inv != null:
		return inv

	inv = Inventory.new()
	inv.name = "Inventory"
	ECS.world.add_entity(inv)
	player.add_relationship(InventoryRelation.owns_inventory(inv))
	return inv

func list_inventory(category: int, search: String) -> Array[ItemView]:
	var out: Array[ItemView] = []
	var player := get_local_player()
	if player == null:
		return out

	var inv := get_inventory_of_player(player)
	if inv == null:
		return out

	var s := search.strip_edges().to_lower()
	var rels := inv.get_relationships(InventoryRelation.any_contains_item())
	for rel in rels:
		var item: Entity = rel.target
		if item == null:
			continue
		if not item.has_component(C_Item):
			continue

		var c_item := item.get_component(C_Item) as C_Item
		if category != -1 and int(c_item.category) != category:
			continue
		if s != "" and c_item.name.to_lower().find(s) == -1:
			continue

		out.append(ItemView.new(item))

	out.sort_custom(func(a: ItemView, b: ItemView) -> bool:
		return a.name < b.name
	)
	return out

func list_ground(category: int, search: String) -> Array[ItemView]:
	var out: Array[ItemView] = []
	if ECS.world == null:
		return out

	var s := search.strip_edges().to_lower()
	var entities := ECS.world.query.with_all([C_OnGround, C_Item]).execute() as Array[Entity]
	for item in entities:
		if item == null:
			continue
		var c_item := item.get_component(C_Item) as C_Item
		if category != -1 and int(c_item.category) != category:
			continue
		if s != "" and c_item.name.to_lower().find(s) == -1:
			continue
		out.append(ItemView.new(item))

	out.sort_custom(func(a: ItemView, b: ItemView) -> bool:
		return a.name < b.name
	)
	return out

func get_item_anywhere(instance_id: int) -> ItemView:
	var entity := _entity_from_id(instance_id)
	if entity == null or not entity.has_component(C_Item):
		return null
	return ItemView.new(entity)

func create_item(into_inventory: bool, name_: String, desc_: String, category: int, stackable: bool, count: int) -> void:
	if ECS.world == null:
		return

	var player := get_local_player()
	if player == null:
		return

	var item := Entity.new()
	item.name = "Item"

	var c_item := C_Item.new()
	c_item.unique_id = 0
	c_item.name = name_
	c_item.description = desc_
	c_item.category = category as Enums.ItemCategory
	c_item.grade = Enums.ItemGrade.COMMON
	item.add_component(c_item)

	if stackable:
		var c_stack := C_ItemStack.new()
		c_stack.is_stackable = true
		c_stack.count = maxi(1, count)
		c_stack.max_stack = 0
		item.add_component(c_stack)

	ECS.world.add_entity(item)

	if into_inventory:
		var inv := ensure_player_inventory(player)
		if inv == null:
			return

		var req := C_InventoryAddRequest.new()
		req.item_entity_id = item.get_instance_id()
		req.count = maxi(1, count)
		inv.add_component(req)
		_process_inventory_now()
		return

	# Ground
	if not item.has_component(C_OnGround):
		item.add_component(C_OnGround.new())

func update_item(instance_id: int, name_: String, desc_: String, new_count: int) -> bool:
	var entity := _entity_from_id(instance_id)
	if entity == null:
		return false
	if not entity.has_component(C_Item):
		return false

	var c_item := entity.get_component(C_Item) as C_Item
	c_item.name = name_
	c_item.description = desc_

	var c_stack := entity.get_component(C_ItemStack) as C_ItemStack
	if c_stack != null and c_stack.is_stackable:
		c_stack.count = maxi(1, new_count)

	return true

func delete_item(instance_id: int) -> bool:
	if ECS.world == null:
		return false

	var entity := _entity_from_id(instance_id)
	if entity == null:
		return false

	var player := get_local_player()
	if player != null:
		var inv := get_inventory_of_player(player)
		if inv != null:
			var containment := InventoryRelation.find_containment_relationship(inv, entity)
			if containment != null:
				inv.remove_relationship(containment)

	ECS.world.remove_entity(entity)
	return true

func drop_to_ground(instance_id: int, count: int, drop_transform: Transform3D = Transform3D.IDENTITY) -> bool:
	var player := get_local_player()
	if player == null:
		return false

	var entity := _entity_from_id(instance_id)
	if entity == null:
		return false

	var req := C_DropRequest.new()
	req.item_entity_id = entity.get_instance_id()
	req.count = maxi(1, count)
	req.drop_transform = drop_transform
	player.add_component(req)
	_process_inventory_now()
	return true

func pickup_from_ground(instance_id: int) -> bool:
	var player := get_local_player()
	if player == null:
		return false

	var entity := _entity_from_id(instance_id)
	if entity == null:
		return false

	var req := C_PickupRequest.new()
	req.item_entity_id = entity.get_instance_id()
	player.add_component(req)
	_process_inventory_now()
	return true

func _process_inventory_now() -> void:
	if ECS.world == null:
		return
	ECS.world.process(0.0, GROUP_INVENTORY)

func _entity_from_id(instance_id: int) -> Entity:
	if instance_id <= 0:
		return null
	var obj := instance_from_id(instance_id)
	if obj == null:
		return null
	return obj as Entity
