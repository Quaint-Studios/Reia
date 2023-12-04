@tool class_name UI_Content extends Panel

func change_tab(tab: UI_Inventory.Tab):
	var current_tab: String = UI_Inventory.Tab.keys()[tab]
	var current_tab_node := current_tab.to_lower().capitalize()

	for content in get_children():
		content.hide()

	var current_content: UI_ContentType = get_node("Content_%s" % current_tab_node) as UI_ContentType
	var category_data := UI_Inventory.instance.inventory.get_category(current_tab)
	if current_content != null:
		current_content.show()
		current_content.load_content(category_data)
