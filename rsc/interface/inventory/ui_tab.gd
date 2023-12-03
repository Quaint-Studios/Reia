@tool class_name UI_Tab extends Button

const CHIP_BLUE = "#558EDD"
const CREAMY_WHITE = "#F9F3E5"

@export var background: Panel
@export var tab_icon: TextureRect
@export var label: Label
@export var category_name: String:
	set(value):
		label.text = value
		category_name = value

@export var selected: bool:
	set(value):
		if value == true:
			_select()
		else:
			_deselect()
		selected = value

func _ready():
	if background == null:
		background = get_node("Selection/Background") as Panel
		tab_icon = get_node("Selection/HBoxContainer/TabIcon") as TextureRect
		label = get_node("Selection/HBoxContainer/Label") as Label

func _deselect():
	background.hide()
	tab_icon.self_modulate = CREAMY_WHITE
	label.self_modulate = CREAMY_WHITE

func _select():
	background.show()
	tab_icon.self_modulate = CHIP_BLUE
	label.self_modulate = CHIP_BLUE
	
	if UI_Inventory.instance == null:
		return
	
	var current_tab = PlayerInventory.Tab[category_name.replace(" ", "_").to_upper()]
	
	UI_Inventory.instance.tab_changed.emit(current_tab)

func update():
	selected = button_group.get_pressed_button() == self

func _on_pressed():
	for button in (button_group.get_buttons() as Array[UI_Tab]):
		button.update()
