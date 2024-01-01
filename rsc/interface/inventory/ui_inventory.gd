@tool class_name UI_Inventory extends Control

static var instance: UI_Inventory

@export var last_category: Inventory.Tab

@export var exit_button: Button
@export var topbar: UI_Topbar # Filter Saves, Filter, and Sort | Currency and Premium Currency | Exit\
@export var sidebar: UI_Sidebar # Categories (selected and unselected)
@export var bottombar: UI_Bottombar # Search | Delete and Select
@export var content: UI_Content # current_content (extends ContentType)

signal tab_changed(tab: Inventory.Tab)

func _ready():
	if topbar == null:
		topbar = %Topbar
	
	if sidebar == null:
		sidebar = %Sidebar
	
	if bottombar == null:
		bottombar = %Bottombar
	
	if content == null:
		content = %Content

	if !Engine.is_editor_hint():
		if instance == null:
			instance = self
		else:
			queue_free()
		
		setup_ui()

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

func setup_ui():
	UIManager.instance.close_ui.connect(hide_inventory_ui)
	
	if GameManager.player.inventory != null:
		content.change_tab(last_category)

func _on_tab_changed(tab: Inventory.Tab):
	content.change_tab(tab)
	last_category = tab
	pass

func _on_exit():
	UIManager.emit_open_ui(UIManager.UI_TYPES.GAME)
