@tool class_name UI_Sidebar extends Control

func setup(tab: UI_Inventory.Tab):
	var current_tab: String = UI_Inventory.Tab.keys()[tab]
	current_tab = current_tab.to_lower().capitalize()
	
	get_node("VBoxContainer/Tabs/Tab_%s" % current_tab)
