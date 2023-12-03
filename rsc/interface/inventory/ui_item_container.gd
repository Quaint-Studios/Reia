@tool class_name UI_ItemContainer extends HFlowContainer

@export var ui_item_scene: PackedScene = preload("res://rsc/interface/inventory/item.tscn")

func clear_items():
	NodeEXT.clear_children(self)

func load_item(item: Item):
	var ui_item := ui_item_scene.instantiate() as UI_Item

	ui_item.item_name = item.name
	ui_item.grade = item.item_grade

	add_child(ui_item)
