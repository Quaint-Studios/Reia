@tool class_name UI_Inventory extends Control

@export var last_category: PlayerInventory.Tab

@export var topbar: UI_Topbar # Filter Saves, Filter, and Sort | Currency and Premium Currency | Exit\
@export var sidebar: UI_Sidebar # Categories (selected and unselected)
@export var bottombar: UI_Bottombar # Search | Delete and Select
@export var content: UI_Content # current_content (extends ContentType)

func setup_inventory(_inventory: Inventory):
	# topbar.setup()
	# sidebar.setup()
	pass
