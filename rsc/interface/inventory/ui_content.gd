@tool class_name UI_Content extends Panel

func change_tab(tab: Inventory.Tab):
	var current_tab: String = Inventory.Tab.keys()[tab]
	var current_tab_node := current_tab.to_lower().capitalize()

	for content in get_children():
		content.hide()

	var current_content: UI_ContentType = get_node("Content_%s" % current_tab_node) as UI_ContentType
	var category_data := GameManager.player.inventory.get_category(current_tab)
	if current_content != null:
		current_content.show()
		current_content.load_content(category_data)
