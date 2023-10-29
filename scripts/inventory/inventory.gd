class_name Inventory extends Resource

@export var categories: Dictionary # [CategoryData]

func add_category(name: String, items: Dictionary = {}): # Dictionary[ItemData]
	var new_category := CategoryData.new()
	new_category.name = name
	new_category.items = items

	categories[name] = new_category
	return self

func add_item(category_name: String, item: ItemData):
	var category := get_category(category_name)

	if category == null:
		return self

	category.add_item(item)
	return self

func get_category(category_name: String) -> CategoryData:
	# Category doesn't exist
	if !categories.has(category_name):
		print_debug("category %s is null | Stack: %s" % [category_name, get_stack()])
		return

	var category = categories[category_name]

	# Shouldn't happen, but be safe and end if not CategoryData type.
	if !category is CategoryData:
		print_debug("category %s is not of type CategoryData | Stack: %s" % [category_name, get_stack()])
		return

	return category

func remove_item(category_name: String, item: ItemData):
	# Category doesn't exist
	if !categories.has(category_name):
		return

	var category = categories[category_name]
