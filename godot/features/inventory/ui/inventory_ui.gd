extends CanvasLayer

var svc: InventoryService

var tab_bar: TabBar
var search_line: LineEdit
var list: ItemList

var id_label: Label
var name_line: LineEdit
var desc_text: TextEdit
var stackable_label: Label
var count_spin: SpinBox

var btn_create_inv: Button
var btn_create_ground: Button
var btn_update: Button
var btn_delete: Button
var btn_drop: Button
var btn_pickup: Button

var _current_tab: int = 0
var _selected_item_instance_id: int = -1

# Tabs: 0..5 are categories, 6 is Ground
const TAB_GROUND := 6

var _ui_root: Control
var _toggle_btn: Button
var _ui_visible: bool = false

func _ready() -> void:
	randomize()

	svc = InventoryService.new()

	_build_ui()
	_refresh_list()

func _build_ui() -> void:
	var root := Control.new()
	root.name = "InventoryRoot"
	root.anchor_left = 0
	root.anchor_top = 0
	root.anchor_right = 1
	root.anchor_bottom = 1
	root.offset_left = 0
	root.offset_top = 0
	root.offset_right = 0
	root.offset_bottom = 0
	root.visible = _ui_visible
	add_child(root)
	_ui_root = root

	_toggle_btn = Button.new()
	_toggle_btn.name = "ToggleInventoryUi"
	_toggle_btn.text = "Hide Inventory UI" if _ui_visible else "Show Inventory UI"
	_toggle_btn.anchor_left = 0.0
	_toggle_btn.anchor_top = 0.0
	_toggle_btn.anchor_right = 0.0
	_toggle_btn.anchor_bottom = 0.0
	_toggle_btn.offset_left = 12
	_toggle_btn.offset_top = 12
	_toggle_btn.offset_right = 220
	_toggle_btn.offset_bottom = 44
	_toggle_btn.z_index = 1000
	var __ := _toggle_btn.pressed.connect(_on_toggle_ui_pressed)
	add_child(_toggle_btn)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.05
	panel.anchor_top = 0.08
	panel.anchor_right = 0.95
	panel.anchor_bottom = 0.92
	root.add_child(panel)

	var main := VBoxContainer.new()
	main.name = "MainVBox"
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(main)

	tab_bar = TabBar.new()
	tab_bar.name = "Tabs"
	tab_bar.add_tab("Weapons")
	tab_bar.add_tab("Equipment")
	tab_bar.add_tab("Soulstones")
	tab_bar.add_tab("Consumables")
	tab_bar.add_tab("Materials")
	tab_bar.add_tab("Quest Items")
	tab_bar.add_tab("Ground")
	__ = tab_bar.tab_changed.connect(_on_tab_changed)
	main.add_child(tab_bar)

	var search_row := HBoxContainer.new()
	search_row.name = "SearchRow"
	main.add_child(search_row)

	var search_lbl := Label.new()
	search_lbl.text = "Search:"
	search_row.add_child(search_lbl)

	search_line = LineEdit.new()
	search_line.name = "SearchLine"
	search_line.placeholder_text = "type item name..."
	search_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	__ = search_line.text_changed.connect(func(_t: String) -> void:
		_refresh_list()
	)
	search_row.add_child(search_line)

	var content := HSplitContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(content)

	list = ItemList.new()
	list.name = "ItemList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	__ = list.item_selected.connect(_on_item_selected)
	content.add_child(list)

	var right := VBoxContainer.new()
	right.name = "RightVBox"
	right.custom_minimum_size = Vector2(360, 0)
	content.add_child(right)

	var details_title := Label.new()
	details_title.text = "Details"
	right.add_child(details_title)

	id_label = Label.new()
	id_label.text = "ID: (none)"
	right.add_child(id_label)

	var name_row := HBoxContainer.new()
	right.add_child(name_row)
	var name_lbl := Label.new()
	name_lbl.text = "Name:"
	name_row.add_child(name_lbl)
	name_line = LineEdit.new()
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_line)

	var stack_row := HBoxContainer.new()
	right.add_child(stack_row)
	stackable_label = Label.new()
	stackable_label.text = "Stackable: -"
	stack_row.add_child(stackable_label)

	var count_lbl := Label.new()
	count_lbl.text = "Count:"
	stack_row.add_child(count_lbl)
	count_spin = SpinBox.new()
	count_spin.min_value = 1
	count_spin.max_value = 999999
	count_spin.step = 1
	count_spin.value = 1
	count_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack_row.add_child(count_spin)

	var desc_lbl := Label.new()
	desc_lbl.text = "Description:"
	right.add_child(desc_lbl)

	desc_text = TextEdit.new()
	desc_text.custom_minimum_size = Vector2(0, 120)
	desc_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_text.size_flags_vertical = Control.SIZE_FILL
	desc_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	right.add_child(desc_text)

	right.add_child(HSeparator.new())

	var crud_row := HBoxContainer.new()
	right.add_child(crud_row)

	btn_create_inv = Button.new()
	btn_create_inv.text = "Create -> Inventory"
	__ = btn_create_inv.pressed.connect(_on_create_inventory)
	crud_row.add_child(btn_create_inv)

	btn_create_ground = Button.new()
	btn_create_ground.text = "Create -> Ground"
	__ = btn_create_ground.pressed.connect(_on_create_ground)
	crud_row.add_child(btn_create_ground)

	var crud_row2 := HBoxContainer.new()
	right.add_child(crud_row2)

	btn_update = Button.new()
	btn_update.text = "Update"
	__ = btn_update.pressed.connect(_on_update)
	crud_row2.add_child(btn_update)

	btn_delete = Button.new()
	btn_delete.text = "Delete"
	__ = btn_delete.pressed.connect(_on_delete)
	crud_row2.add_child(btn_delete)

	right.add_child(HSeparator.new())

	var act_row := HBoxContainer.new()
	right.add_child(act_row)

	btn_drop = Button.new()
	btn_drop.text = "Drop"
	__ = btn_drop.pressed.connect(_on_drop)
	act_row.add_child(btn_drop)

	btn_pickup = Button.new()
	btn_pickup.text = "Pickup"
	__ = btn_pickup.pressed.connect(_on_pickup)
	act_row.add_child(btn_pickup)

	_update_buttons_enabled()

func _on_toggle_ui_pressed() -> void:
	_ui_visible = not _ui_visible
	if is_instance_valid(_ui_root):
		_ui_root.visible = _ui_visible
	if is_instance_valid(_toggle_btn):
		_toggle_btn.text = "Hide Inventory UI" if _ui_visible else "Show Inventory UI"

func _refresh_list() -> void:
	list.clear()
	_selected_item_instance_id = -1
	_fill_details(null)

	var search := search_line.text
	if _current_tab == TAB_GROUND:
		var items := svc.list_ground(-1, search)
		for it in items:
			var __ := list.add_item(_format_item(it))
			list.set_item_metadata(list.item_count - 1, it.instance_id)
	else:
		var items := svc.list_inventory(_current_tab, search)
		for it in items:
			var __ := list.add_item(_format_item(it))
			list.set_item_metadata(list.item_count - 1, it.instance_id)

	_update_buttons_enabled()

func _format_item(it: InventoryService.ItemView) -> String:
	if it.stackable:
		return "%s x%d" % [it.name, it.count]
	return it.name

func _fill_details(it: InventoryService.ItemView) -> void:
	if it == null:
		id_label.text = "ID: (none)"
		name_line.text = ""
		desc_text.text = ""
		stackable_label.text = "Stackable: -"
		count_spin.editable = false
		count_spin.value = 1
		return

	id_label.text = "ID: %s" % str(it.instance_id)
	name_line.text = it.name
	desc_text.text = it.description
	stackable_label.text = "Stackable: %s" % ("Yes" if it.stackable else "No")
	count_spin.editable = it.stackable
	count_spin.value = it.count

func _update_buttons_enabled() -> void:
	var has_sel := _selected_item_instance_id != -1

	btn_update.disabled = not has_sel
	btn_delete.disabled = not has_sel

	btn_drop.disabled = (not has_sel) or (_current_tab == TAB_GROUND)
	btn_pickup.disabled = (not has_sel) or (_current_tab != TAB_GROUND)

func _on_tab_changed(tab: int) -> void:
	_current_tab = tab
	_refresh_list()

func _on_item_selected(index: int) -> void:
	var id_: int = list.get_item_metadata(index)
	_selected_item_instance_id = id_
	_fill_details(svc.get_item_anywhere(id_))
	_update_buttons_enabled()

func _on_create_inventory() -> void:
	_create(true)

func _on_create_ground() -> void:
	_create(false)

func _create(into_inventory: bool) -> void:
	var category := Enums.ItemCategory.MATERIAL if (_current_tab == TAB_GROUND) else _current_tab
	var stackable := (category == Enums.ItemCategory.CONSUMABLE or category == Enums.ItemCategory.MATERIAL)

	var base_name := "New Item"
	match category:
		Enums.ItemCategory.WEAPON: base_name = "New Weapon"
		Enums.ItemCategory.EQUIPMENT: base_name = "New Equipment"
		Enums.ItemCategory.SOULSTONE: base_name = "New Soulstone"
		Enums.ItemCategory.CONSUMABLE: base_name = "New Consumable"
		Enums.ItemCategory.MATERIAL: base_name = "New Material"
		Enums.ItemCategory.QUEST_ITEM: base_name = "New Quest Item"

	svc.create_item(into_inventory, base_name, "edit me", int(category), stackable, 3)
	_refresh_list()

func _on_update() -> void:
	if _selected_item_instance_id == -1:
		return
	var __ := svc.update_item(_selected_item_instance_id, name_line.text, desc_text.text, int(count_spin.value))
	_refresh_list()

func _on_delete() -> void:
	if _selected_item_instance_id == -1:
		return
	var __ := svc.delete_item(_selected_item_instance_id)
	_refresh_list()

func _on_drop() -> void:
	if _selected_item_instance_id == -1:
		return
	if svc.drop_to_ground(_selected_item_instance_id, int(count_spin.value)):
		_refresh_list()

func _on_pickup() -> void:
	if _selected_item_instance_id == -1:
		return
	if svc.pickup_from_ground(_selected_item_instance_id):
		_refresh_list()
