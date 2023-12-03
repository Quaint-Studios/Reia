@tool class_name UI_Sidebar extends Control

func setup(tab: PlayerInventory.Tab):
	var current_tab: String = PlayerInventory.Tab.keys()[tab]
	current_tab = current_tab.to_lower().capitalize()
	
	get_node("VBoxContainer/Tabs/Tab_%s" % current_tab)
