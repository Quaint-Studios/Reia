class_name CategoryData extends Resource
# Weapon, Equipment, Soulstones, Consumables (Food, Potions, etc), Materials, Quest

@export var name: String = ""
@export var items: Dictionary # [ItemData]

func add_item(item: ItemData):
	items[item.name] = item
	return self

func get_item(item_name: String):
	if !items.has(item_name):
		return false # Item doesn't exist

	return items[item_name]

func increment_item(item_name: String, quantity:= 1):
	var item = get_item(item_name)

	if item == false:
		return false

	if !is_instance_of(item, StackableItemData):
		return false # Item isn't stackable

	(item as StackableItemData).increment_item(quantity)
	return self

func decrement_item(item_name: String, quantity:= -1):
	increment_item(item_name, quantity) # Hehe lazy
	return self
