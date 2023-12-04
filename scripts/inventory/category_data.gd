class_name CategoryData extends Resource
# Weapons, Equipment, Soulstones, Consumables (Food, Potions, etc), Materials, Quest

@export var name: String = ""
@export var items: Dictionary # [Item]

func add_item(item: Item) -> CategoryData:
	items[item.name] = item # TODO: Append experience to existing item
	return self

func get_item(item_name: String) -> Item:
	if !items.has(item_name):
		print_debug("Item %s in category %s is null | Stack: %s" % [item_name, name, get_stack()])
		return # Item doesn't exist

	return items[item_name]

func increment_item(item_name: String, quantity:= 1):
	var item = get_item(item_name)

	if item == null:
		return self

	if !item is StackableItem:
		print_debug("Item %s in category %s is not a StackableObject | Stack: %s" % [item_name, name, get_stack()])
		return self # Item isn't stackable

	(item as StackableItem).increment_item(quantity)
	return self

func decrement_item(item_name: String, quantity:= -1):
	increment_item(item_name, quantity) # Hehe lazy
	return self
