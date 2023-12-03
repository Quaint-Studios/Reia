@tool class_name UI_ItemContainer extends HFlowContainer

@export var ui_item_scene: PackedScene = preload("res://rsc/interface/inventory/item.tscn")

func load_inventory(_inventory: Inventory, category_name: String):
	NodeEXT.clear_children(self)
	
	var category := _inventory.get_category(category_name)
	
	var items := category.items.values() as Array[Item]
	
	for item in items:
		var ui_item := ui_item_scene.instantiate() as UI_Item

		ui_item.item_name = item.name
		ui_item.grade = item.item_grade

		add_child(ui_item)
