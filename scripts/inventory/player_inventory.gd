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
	if event.is_action_pressed("inventory") || event.is_action_pressed("quit"):
		toggle_inventory()

func toggle_inventory():
	self.visible = !self.visible
	GameManager.current_ui = GameManager.UI_TYPES.INVENTORY if self.visible else GameManager.UI_TYPES.PLAY
	GameManager.update_fps()

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

	for tab in header_tabs:
		var node = header_tab.instantiate() as Control
		var btn: Button = node.get_node("Button") as Button
		var bg: Panel = node.get_node("SelectedBG") as Panel
		var icon: TextureRect = node.get_node("Icon") as TextureRect

		btn.mouse_entered.connect(_on_btn_mouse_entered.bind(btn))
		btn.mouse_exited.connect(_on_btn_mouse_entered.bind(btn))
		btn.modulate = Color("ffffff", 1)

		node.name = tab.name
		var atlas = AtlasTexture.new()
		atlas.set_atlas(ui_header_atlas)

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

func _on_btn_pressed(btn: Button):
	for i in header_tab_nodes.size():
		var tab = header_tab_nodes[i]
		if btn.get_parent() == tab:
			tab.set_meta("selected", true)
			var margin = %IndicatorMargin as MarginContainer
			margin.add_theme_constant_override("margin_right", Constants.INVENTORY_SELECTOR_POS(i))
		else:
			tab.set_meta("selected", false)
		handle_tab_style(tab)

func _on_btn_mouse_entered(btn: Button):
	if !btn.get_meta("selected", false):
		btn.modulate.a = 1

func _on_btn_mouse_exited(btn: Button):
	if !btn.get_meta("selected", false):
		btn.modulate.a = 0
