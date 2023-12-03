@tool class_name UI_Inventory extends Control

static var instance: UI_Inventory

@export var inventory: Inventory:
	set(value):
		if value != null:
			if is_node_ready():
				get_node("UI").show()

@export var last_category: PlayerInventory.Tab

@export var topbar: UI_Topbar # Filter Saves, Filter, and Sort | Currency and Premium Currency | Exit\
@export var sidebar: UI_Sidebar # Categories (selected and unselected)
@export var bottombar: UI_Bottombar # Search | Delete and Select
@export var content: UI_Content # current_content (extends ContentType)

signal tab_changed(tab: PlayerInventory.Tab)

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()

	if inventory == null:
		get_node("UI").hide()

func setup_inventory(_inventory: Inventory):
	# topbar.setup()
	# sidebar.setup()
	pass


func _on_tab_changed(tab: PlayerInventory.Tab):
	content.change_tab(tab)
	pass
