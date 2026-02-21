extends CanvasLayer

var svc: InventoryDemoService

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
var _selected_item_id: String = ""

# Tabs: 0..5 are categories, 6 is “Ground”
const TAB_GROUND := 6

var _ui_root: Control
var _toggle_btn: Button
var _ui_visible: bool = false

func _ready() -> void:
	randomize()

	svc = InventoryDemoService.new()
	svc.seed_demo_data()

	_build_ui()
	_refresh_list()

func _build_ui() -> void:
	# NEW: Toggle button (kept outside the UI root so it remains clickable when UI is hidden)
	var root := Control.new()
	root.name = "InventoryDemoRoot"
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
	_toggle_btn.name = "ToggleInventoryDemoUi"
	_toggle_btn.text = "Hide Inventory UI"
	_toggle_btn.anchor_left = 0.0
	_toggle_btn.anchor_top = 0.0
	_toggle_btn.anchor_right = 0.0
	_toggle_btn.anchor_bottom = 0.0
	_toggle_btn.offset_left = 12
	_toggle_btn.offset_top = 12
	_toggle_btn.offset_right = 220
	_toggle_btn.offset_bottom = 44
	var __ := _toggle_btn.pressed.connect(_on_toggle_ui_pressed)
	add_child(_toggle_btn)

	# Main panel
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

	# Tabs
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

	# Search
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

	# Content split
	var content := HSplitContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(content)

	# Left: list
	list = ItemList.new()
	list.name = "ItemList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	__ = list.item_selected.connect(_on_item_selected)
	content.add_child(list)

	# Right: details + actions
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

	# CRUD buttons
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

	# Actions
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
	_toggle_btn.text = "Hide Inventory UI" if _ui_visible else "Show Inventory UI"


func _refresh_list() -> void:
	list.clear()
	_selected_item_id = ""
	_fill_details(null)

	var search := search_line.text
	if _current_tab == TAB_GROUND:
		# show all ground items across categories; keep name search
		var items := svc.list_ground(-1, search)
		for it in items:
			var __ := list.add_item(_format_item(it))
			list.set_item_metadata(list.item_count - 1, it.unique_id)
	else:
		var items := svc.list_inventory(_current_tab, search)
		for it in items:
			var __ := list.add_item(_format_item(it))
			list.set_item_metadata(list.item_count - 1, it.unique_id)

	_update_buttons_enabled()

func _format_item(it: InventoryDemoService.Item) -> String:
	if it.stackable:
		return "%s x%d" % [it.name, it.count]
	return it.name

func _fill_details(it: InventoryDemoService.Item) -> void:
	if it == null:
		id_label.text = "ID: (none)"
		name_line.text = ""
		desc_text.text = ""
		stackable_label.text = "Stackable: -"
		count_spin.editable = false
		count_spin.value = 1
		return

	id_label.text = "ID: %s" % it.unique_id
	name_line.text = it.name
	desc_text.text = it.description
	stackable_label.text = "Stackable: %s" % ("Yes" if it.stackable else "No")
	count_spin.editable = it.stackable
	count_spin.value = it.count

func _update_buttons_enabled() -> void:
	var has_sel := _selected_item_id != ""

	btn_update.disabled = not has_sel
	btn_delete.disabled = not has_sel

	# Drop/Pickup depend on which tab you’re viewing
	btn_drop.disabled = (not has_sel) or (_current_tab == TAB_GROUND)
	btn_pickup.disabled = (not has_sel) or (_current_tab != TAB_GROUND)

func _on_tab_changed(tab: int) -> void:
	_current_tab = tab
	_refresh_list()

func _on_item_selected(index: int) -> void:
	var id_: String = list.get_item_metadata(index)
	_selected_item_id = id_
	_fill_details(svc.get_item_anywhere(id_))
	_update_buttons_enabled()

# --- CRUD ---

func _on_create_inventory() -> void:
	_create(true)

func _on_create_ground() -> void:
	_create(false)

func _create(into_inventory: bool) -> void:
	# Create in current category tab; if on Ground tab, default to MATERIAL for demo.
	var category := InventoryDemoService.Category.MATERIAL if (_current_tab == TAB_GROUND) else _current_tab
	var stackable := (category == InventoryDemoService.Category.CONSUMABLE or category == InventoryDemoService.Category.MATERIAL)

	var base_name := "New Item"
	match category:
		InventoryDemoService.Category.WEAPON: base_name = "New Weapon"
		InventoryDemoService.Category.EQUIPMENT: base_name = "New Equipment"
		InventoryDemoService.Category.SOULSTONE: base_name = "New Soulstone"
		InventoryDemoService.Category.CONSUMABLE: base_name = "New Consumable"
		InventoryDemoService.Category.MATERIAL: base_name = "New Material"
		InventoryDemoService.Category.QUEST_ITEM: base_name = "New Quest Item"

	var __ := svc.create_item(into_inventory, base_name, "edit me", category, stackable, 3)
	_refresh_list()

func _on_update() -> void:
	if _selected_item_id == "":
		return
	var __ := svc.update_item(_selected_item_id, name_line.text, desc_text.text, int(count_spin.value))
	_refresh_list()

func _on_delete() -> void:
	if _selected_item_id == "":
		return
	var __ := svc.delete_item(_selected_item_id)
	_refresh_list()

# --- Actions ---

func _on_drop() -> void:
	if _selected_item_id == "":
		return
	if svc.drop_to_ground(_selected_item_id):
		_refresh_list()

func _on_pickup() -> void:
	if _selected_item_id == "":
		return
	if svc.pickup_from_ground(_selected_item_id):
		_refresh_list()
