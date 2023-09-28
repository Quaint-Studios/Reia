class_name Inventory extends Resource

@export var categories: Array[CategoryData]

func add_category(name: String, slots: Array[SlotData] = []):
	var new_category = CategoryData.new()
	new_category.name = name
	new_category.slots = slots

	categories.append(new_category)
	return self
