class_name CategoryData extends Resource
# Weapons, Equipment, Soulstones, Consumables (Food, Potions, etc), Materials, Quest

@export var name: String = ""
@export var items: Dictionary # [Item]

func add_item(item: Item) -> CategoryData:
	if (name == Inventory.Tab.keys()[Inventory.Tab.WEAPONS]
	and item is Weapon
	and items.has(item.name)):
		var xp := Weapon.get_level_xp((item as Weapon).level)
		var weapon: Weapon = items[item.name]
		weapon.add_xp(floori(xp / 4.0)) # Add 1/4th of the total xp to the weapon

		print("Item is a duplicate, adding exp")
		#(items[item.name] as Weapon)#.enhance(wea)
	items[item.name] = item # TODO: Append experience to existing item
	return self

# TODO: Test
func remove_item(item_name: String) -> CategoryData:
	if items.has(item_name):
		var __ := items.erase(item_name)
	return self

func get_item(item_name: String) -> Item:
	if !items.has(item_name):
		print_debug("Item %s in category %s is null | Stack: %s" % [item_name, name, get_stack()])
		return # Item doesn't exist

	return items[item_name]

func increment_item(item_name: String, quantity := 1) -> CategoryData:
	var item := get_item(item_name)

	if item == null:
		return self

	if !item is StackableItem:
		print_debug("Item %s in category %s is not a StackableObject | Stack: %s" % [item_name, name, get_stack()])
		return self # Item isn't stackable

	(item as StackableItem).quantity += quantity
	return self

func decrement_item(item_name: String, quantity := -1) -> CategoryData:
	increment_item(item_name, quantity).end() # Hehe lazy
	return self

func end() -> void:
	pass

func toJSON() -> Dictionary:
	var data := {
		"name": name,
		"items": {}
	}

	@warning_ignore("unsafe_method_access")
	var __ := items.keys().all(func(key: String) -> void: data["items"].merge({"%s" % key: (items[key]).toJSON()}))

	return data
