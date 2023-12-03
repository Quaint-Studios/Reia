@tool class_name UI_Content extends Panel

func change_tab(tab: PlayerInventory.Tab):
	var current_tab: String = PlayerInventory.Tab.keys()[tab]
	current_tab = current_tab.to_lower().capitalize()

	for content in get_children():
		content.hide()

	var current_content: UI_ContentType = get_node("Content_%s" % current_tab) as UI_ContentType
	current_content.load_content(PlayerInventory)
