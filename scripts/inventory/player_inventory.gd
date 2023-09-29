class_name PlayerInventory extends Control

# Core
@export var inventory: Inventory
@export var essence: int = 0

@export var ui_shown: bool = false

# Resources
@export var ui_header_atlas: CompressedTexture2D
@export var header_tab: PackedScene

# Cache
var header_tab_nodes: Array[Control]

func _ready():
	create_inventory()
	setup_ui()

func _input(event: InputEvent):
	# TODO: You'll eventually run into an issue where you need to hide all UI.
	if GameManager.current_ui == GameManager.UI_TYPES.PLAY:
		if event.is_action_pressed("inventory"):
			show_inventory_ui()
		return

	if GameManager.current_ui == GameManager.UI_TYPES.INVENTORY:
		if event.is_action_pressed("inventory") || event.is_action_pressed("quit"):
			hide_inventory_ui()
		return

func show_inventory_ui():
	GameManager.current_ui = GameManager.UI_TYPES.INVENTORY
	self.visible = true

func hide_inventory_ui():
	GameManager.current_ui = GameManager.UI_TYPES.PLAY
	self.visible = false

func create_inventory():
	if inventory != null:
		print("An inventory already exists here.")
		return

	inventory = Inventory.new()
	(inventory
		.add_category("Weapons")
		.add_category("Soulstones")
		.add_category("Consumables")
		.add_category("Quest Items")
		.add_category("Equipment")
		.add_category("Materials"))


func setup_ui():
	setup_header_tabs()

class HeaderTab:
	var name: String
	var pos: Vector2

	func _init(_name, _pos):
		name = _name
		pos = _pos

func setup_header_tabs():
	var header_tabs: Array[HeaderTab] = [
		HeaderTab.new("Weapons", Vector2(0, 1)),
		HeaderTab.new("Soulstones", Vector2(0, 1)),
		HeaderTab.new("Consumables",Vector2(0, 1)),
		HeaderTab.new("Quest Items", Vector2(0, 1)),
		HeaderTab.new("Equipment", Vector2(0, 1)),
		HeaderTab.new("Materials", Vector2(0, 1))
	]

	for i in header_tabs.size():
		var tab = header_tabs[i]

		var node = header_tab.instantiate() as Control
		node.name = tab.name
		if tab.name == starting_tab:
			update_indicator_pos(i)

		var btn: Button = node.get_node("Button") as Button
		var icon: TextureRect = node.get_node("Icon") as TextureRect

		btn.mouse_entered.connect(_on_btn_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_btn_mouse_exited.bind(btn))
		btn.pressed.connect(_on_btn_pressed.bind(btn))

		var atlas = AtlasTexture.new()
		atlas.set_atlas(ui_header_atlas)
		atlas.region = Rect2(
			Constants.DEFAULT_ATLAS_SIZE * tab.pos.x,
			Constants.DEFAULT_ATLAS_SIZE * tab.pos.y,
			Constants.DEFAULT_ATLAS_SIZE,
			Constants.DEFAULT_ATLAS_SIZE
		)
		icon.texture = atlas

		%HeaderContainer.add_child(node)



func handle_tab_style(node: Control):
	var btn: Button = node.get_node("Button") as Button
	var bg: Panel = node.get_node("SelectedBG") as Panel
	var icon: TextureRect = node.get_node("Icon") as TextureRect
	var selected: bool = node.get_meta("selected", false)

	if selected:
		btn.modulate.a = 1
		bg.modulate.a = 1
		icon.modulate = Color(Constants.INVENTORY_BG_COLOR)
	else:
		btn.modulate.a = 0
		bg.modulate.a = 0
		icon.modulate = Color(Constants.INVENTORY_FG_COLOR)

func update_indicator_pos(i: int):
	var margin = %IndicatorMargin as MarginContainer
	margin.add_theme_constant_override("margin_right", Constants.INVENTORY_SELECTOR_POS(i))

func _on_btn_pressed(btn: Button):
	for i in %HeaderContainer.get_child_count():
		var tab = %HeaderContainer.get_child(i)
		if btn.get_parent() == tab:
			tab.set_meta("selected", true)
			update_indicator_pos(i)
		else:
			tab.set_meta("selected", false)
		handle_tab_style(tab)

func _on_btn_mouse_entered(btn: Button):
	if !btn.get_meta("selected", false):
		btn.modulate.a = 1

func _on_btn_mouse_exited(btn: Button):
	if !btn.get_meta("selected", false):
		btn.modulate.a = 0
