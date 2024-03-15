@tool class_name UI_Sidebar extends Control

func setup(tab: Inventory.Tab):
	var current_tab: String = Inventory.Tab.keys()[tab]
	current_tab = current_tab.to_lower().capitalize()
	
	get_node("VBoxContainer/Tabs/Tab_%s" % current_tab)
