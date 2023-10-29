class_name CategoryData extends Resource
# Weapon, Equipment, Soulstones, Consumables (Food, Potions, etc), Materials, Quest

@export var name: String = ""
@export var items: Dictionary # [ItemData]

func add_item(item: ItemData):
	items[item.name] = item
	return self

func get_item(item_name: String) -> ItemData:
	if !items.has(item_name):
		print_debug("Item %s in category %s is null | Stack: %s" % [item_name, name, get_stack()])
		return # Item doesn't exist

	return items[item_name]

func increment_item(item_name: String, quantity:= 1):
	var item = get_item(item_name)

	if item == null:
		return self

	if !item is StackableItemData:
		print_debug("Item %s in category %s is not a StackableObject | Stack: %s" % [item_name, name, get_stack()])
		return self # Item isn't stackable

	(item as StackableItemData).increment_item(quantity)
	return self

func decrement_item(item_name: String, quantity:= -1):
	increment_item(item_name, quantity) # Hehe lazy
	return self
