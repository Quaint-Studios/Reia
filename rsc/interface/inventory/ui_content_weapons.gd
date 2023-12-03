@tool extends UI_ContentType

@export var item_container: UI_ItemContainer

func _ready():
	if item_container == null:
		item_container = get_node("ItemContainer") as UI_ItemContainer

func load_content(category_data: CategoryData):
	item_container.clear_items()
	
	for item in category_data.items.values() as Array[Item]:
		item_container.load_item(item)
