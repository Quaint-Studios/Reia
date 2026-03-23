class_name InventoryRelation

# Relationship Functions
static func owns_inventory(inventory: Entity) -> Relationship:
	return Relationship.new(C_OwnsInventory.new(), inventory)

static func any_owns_inventory() -> Relationship:
	return Relationship.new(C_OwnsInventory.new(), null)

static func contains_item(item: Entity, count: int = 1) -> Relationship:
	var rel := C_ContainsItem.new()
	rel.count = count
	return Relationship.new(rel, item)

static func any_contains_item() -> Relationship:
	return Relationship.new(C_ContainsItem.new(), null)

static func trade_offer(item: Entity, trade_id: String, count: int = 1) -> Relationship:
	var rel := C_TradeOffer.new()
	rel.trade_id = trade_id
	rel.count = count
	return Relationship.new(rel, item)

# Helper Functions
static func get_inventory_of_player(player: Entity) -> Entity:
	var rels := player.get_relationships(any_owns_inventory())
	if rels.is_empty():
		return null
	return rels[0].target # as Entity

static func inventory_slot_count(inventory: Entity) -> int:
	return inventory.get_relationships(any_contains_item()).size()

static func can_add_slots(inventory: Entity, slots: int) -> bool:
	var c_inv := inventory.get_component(C_Inventory) as C_Inventory
	if c_inv == null:
		return false
	if c_inv.capacity == 0:
		return true
	return (inventory_slot_count(inventory) + slots) <= c_inv.capacity

static func find_containment_relationship(inventory: Entity, item: Entity) -> Relationship:
	# find the exact relationship instance so it can be removed
	var rels := inventory.get_relationships(any_contains_item())
	for rel in rels:
		if rel.target == item:
			return rel
	return null

static func is_item_in_inventory(inventory: Entity, item: Entity) -> bool:
	return find_containment_relationship(inventory, item) != null
