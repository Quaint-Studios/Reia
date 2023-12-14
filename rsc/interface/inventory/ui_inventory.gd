@tool class_name UI_Inventory extends Control

static var instance: UI_Inventory

@export var inventory: Inventory

@export var last_category: Tab
enum Tab { WEAPONS, SOULSTONES, CONSUMABLES, QUEST_ITEMS, EQUIPMENT, MATERIALS }

@export var exit_button: Button
@export var topbar: UI_Topbar # Filter Saves, Filter, and Sort | Currency and Premium Currency | Exit\
@export var sidebar: UI_Sidebar # Categories (selected and unselected)
@export var bottombar: UI_Bottombar # Search | Delete and Select
@export var content: UI_Content # current_content (extends ContentType)

signal tab_changed(tab: Tab)

func _ready():
	if topbar == null:
		topbar = get_node("Topbar")
	
	if sidebar == null:
		sidebar = get_node("Sidebar")
	
	if bottombar == null:
		bottombar = get_node("Bottombar")
	
	if content == null:
		content = get_node("Content")

	if !Engine.is_editor_hint():
		if instance == null:
			instance = self
		else:
			queue_free()
		
		setup_inventory()

func _input(event: InputEvent):
	# TODO: You'll eventually run into an issue where you need to hide all UI.
	
	if GameManager.current_ui == GameManager.UI_TYPES.PLAY:
		if event.is_action_pressed("inventory"):
			show_inventory_ui()
		return

	if GameManager.current_ui == GameManager.UI_TYPES.INVENTORY:
		if event.is_action_pressed("inventory") || event.is_action_pressed("quit"):
			hide_inventory_ui(UIManager.UI_TYPES.GAME)
		return

func show_inventory_ui():
	GameManager.current_ui = GameManager.UI_TYPES.INVENTORY
	self.visible = true

func hide_inventory_ui(ui: UIManager.UI_TYPES):
	if ui == UIManager.UI_TYPES.INVENTORY:
		return
	GameManager.current_ui = GameManager.UI_TYPES.PLAY
	self.visible = false

func setup_inventory():
	UIManager.instance.close_ui.connect(hide_inventory_ui)
	
	if inventory == null:
		create_inventory()
	pass

func create_inventory():
	if inventory != null:
		print("An inventory already exists here.")
		return

	var keys = Tab.keys()
	inventory = Inventory.new()
	(inventory
		.add_category(keys[Tab.WEAPONS])
		.add_category(keys[Tab.SOULSTONES])
		.add_category(keys[Tab.CONSUMABLES])
		.add_category(keys[Tab.EQUIPMENT])
		.add_category(keys[Tab.MATERIALS])
		.add_category(keys[Tab.QUEST_ITEMS]))

	populate_test_data()
	
	content.change_tab(last_category)

func populate_test_data():
	var keys = Tab.keys()
	
	var weapons_tab = keys[Tab.WEAPONS]
	
	inventory\
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))\
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))\
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))\
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))\
	.add_item(weapons_tab, load(WeaponIndex.WOODEN_SWORD))\

	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP))\
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP))\
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP))\
	.add_item(weapons_tab, load(WeaponIndex.SAPPHIRITE_WHIP))\

	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND))\
	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND))\
	.add_item(weapons_tab, load(WeaponIndex.PYROMANCERS_WAND))\

	.add_item(weapons_tab, load(WeaponIndex.ROBINS_BOW))\
	.add_item(weapons_tab, load(WeaponIndex.ROBINS_BOW))\

	.add_item(weapons_tab, load(WeaponIndex.ETHEREAL_BOW))\
	.add_item(weapons_tab, load(WeaponIndex.ETHEREAL_BOW))\

	.add_item(weapons_tab, load(WeaponIndex.STARLIT_SWORD))

func _on_tab_changed(tab: Tab):
	content.change_tab(tab)
	last_category = tab
	pass

func _on_exit():
	UIManager.emit_open_ui(UIManager.UI_TYPES.GAME)
