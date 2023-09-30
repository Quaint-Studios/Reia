class_name Inventory extends Resource

@export var categories: Array[CategoryData]

func add_category(name: String, slots: Array[SlotData] = []):
	var new_category = CategoryData.new()
	new_category.name = name
	new_category.slots = slots

	categories.append(new_category)
	return self

func add_item(category_name: String, item: ItemData):
	var category: CategoryData = get_category(category_name)
	category.add_item(item)
	return self

func get_category(category_name: String) -> CategoryData:
	var filtered = categories.filter(func(elem): return elem.name == category_name)

	# Category doesn't exist
	if filtered.size() <= 0:
		return

	var category = filtered.front()

	# Shouldn't happen, but be safe and end if null.
	if category == null:
		return

	return category
