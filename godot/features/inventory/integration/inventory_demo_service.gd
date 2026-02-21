class_name InventoryDemoService
extends RefCounted

enum Category {WEAPON, EQUIPMENT, SOULSTONE, CONSUMABLE, MATERIAL, QUEST_ITEM}

class Item:
	var unique_id: String
	var name: String
	var description: String
	var category: int
	var stackable: bool
	var count: int

	func _init(id_: String, name_: String, desc_: String, cat_: int, stackable_: bool, count_: int) -> void:
		unique_id = id_
		name = name_
		description = desc_
		category = cat_
		stackable = stackable_
		count = count_

# Ownership for demo: inventory is a dict, ground is a dict
var _inventory: Dictionary = {} # id -> Item
var _ground: Dictionary = {} # id -> Item

func list_inventory(category: int, search: String) -> Array[Item]:
	return _filter(_inventory, category, search)

func list_ground(category: int, search: String) -> Array[Item]:
	# ground tab can show all categories; pass -1 to skip category filter
	return _filter(_ground, category, search)

func create_item(into_inventory: bool, name_: String, desc_: String, category: int, stackable: bool, count: int) -> Item:
	if not stackable:
		count = 1
	else:
		count = max(1, count)

	var id_ := _new_id()
	var item := Item.new(id_, name_, desc_, category, stackable, count)
	if into_inventory:
		_inventory[id_] = item
	else:
		_ground[id_] = item
	return item

func update_item(id_: String, name_: String, desc_: String, new_count: int) -> bool:
	var item := get_item_anywhere(id_)
	if item == null:
		return false

	item.name = name_
	item.description = desc_
	if item.stackable:
		item.count = max(1, new_count)
	return true

func delete_item(id_: String) -> bool:
	if _inventory.has(id_):
		_inventory.erase(id_)
		return true
	if _ground.has(id_):
		_ground.erase(id_)
		return true
	return false

func drop_to_ground(id_: String) -> bool:
	if not _inventory.has(id_):
		return false
	_ground[id_] = _inventory[id_]
	_inventory.erase(id_)
	return true

func pickup_from_ground(id_: String) -> bool:
	if not _ground.has(id_):
		return false
	_inventory[id_] = _ground[id_]
	_ground.erase(id_)
	return true

func get_item_anywhere(id_: String) -> Item:
	if _inventory.has(id_): return _inventory[id_] as Item
	if _ground.has(id_): return _ground[id_] as Item
	return null

func seed_demo_data() -> void:
	create_item(true, "Rusty Sword", "A worn 1h sword.", Category.WEAPON, false, 1)
	create_item(true, "Cloth Hood", "Basic cloth headgear.", Category.EQUIPMENT, false, 1)
	create_item(true, "Health Potion", "Restores HP.", Category.CONSUMABLE, true, 5)
	create_item(false, "Iron Ore", "Harvested ore.", Category.MATERIAL, true, 12)
	create_item(false, "Ancient Letter", "Quest evidence.", Category.QUEST_ITEM, false, 1)

func _filter(store: Dictionary, category: int, search: String) -> Array[Item]:
	var out: Array[Item] = []
	var s := search.strip_edges().to_lower()

	for k in store.keys():
		var it := store[k] as Item
		if category != -1 and it.category != category:
			continue
		if s != "" and it.name.to_lower().find(s) == -1:
			continue
		out.append(it)

	# stable-ish ordering
	out.sort_custom(func(a: Item, b: Item) -> bool:
		return a.name < b.name
	)
	return out

func _new_id() -> String:
	# good enough for demo; replace with UUID later
	return "%s_%s" % [Time.get_unix_time_from_system(), randi()]
