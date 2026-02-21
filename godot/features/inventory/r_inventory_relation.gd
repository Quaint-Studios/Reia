class_name InventoryRelation

# Relationship Functions
static func owns_inventory(inventory: Entity) -> Relationship:
	return Relationship.new(C_OwnsInventory.new(), inventory)

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
static func can_add(inventory: Entity, additional_slots: int) -> bool:
	var c_inv := inventory.get_component(C_Inventory) as C_Inventory
	if c_inv == null:
		return false
	if c_inv.capacity == 0:
		return true

	var current_slots := inventory.get_relationships(any_contains_item()).size()
	return (current_slots + additional_slots) <= c_inv.capacity
