@tool
class_name MapViewportOverlay
extends Control

## In-viewport floating overlay organism for the Map Editor.
## Houses the primary tool selector, shape preset flyout, and handles tool shortcuts.

var editor_context: MapEditorContext = null
var editor_state_bus: MapEditorStateBus = null

var _toolbar_column: VBoxContainer = null
var _select_button: RoundIconButtonAtom = null
var _shape_button: RoundIconButtonAtom = null
var _shape_flyout: ShapeFlyoutContainer = null
var _status_panel: PanelContainer = null
var _status_label: Label = null


func _init() -> void:
	name = "MapEditorViewportOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0


var plugin_base_path: String = ""


func setup(context: MapEditorContext, state_bus: MapEditorStateBus, p_plugin_path: String = "") -> void:
	editor_context = context
	editor_state_bus = state_bus
	plugin_base_path = p_plugin_path

	if editor_state_bus != null:
		if not editor_state_bus.on_tool_changed.is_connected(_on_external_tool_changed):
			editor_state_bus.on_tool_changed.connect(_on_external_tool_changed)
		if not editor_state_bus.on_transform_status_changed.is_connected(_on_transform_status_changed):
			editor_state_bus.on_transform_status_changed.connect(_on_transform_status_changed)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	_build_ui()


func get_plugin_path() -> String:
	if not plugin_base_path.is_empty():
		return plugin_base_path
	var script_path: String = (get_script() as Script).resource_path
	var marker: String = "/addons/map_editor"
	var idx: int = script_path.find(marker)
	if idx != -1:
		return script_path.substr(0, idx + marker.length())
	return (get_script() as Script).resource_path.get_base_dir().get_base_dir().get_base_dir()


func get_addon_base_path() -> String:
	return get_plugin_path()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# Main vertical toolbar column (top-left)
	_toolbar_column = VBoxContainer.new()
	_toolbar_column.name = "ToolbarColumn"
	_toolbar_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toolbar_column.position = Vector2(10, 46)
	_toolbar_column.custom_minimum_size = Vector2(36, 0)
	_toolbar_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_toolbar_column.add_theme_constant_override("separation", 8)
	add_child(_toolbar_column)

	# Select Tool Button
	_select_button = RoundIconButtonAtom.new()
	var select_icon_path: String = get_addon_base_path().path_join("assets/icons/icon_select.svg")
	if ResourceLoader.exists(select_icon_path):
		_select_button.icon = load(select_icon_path) as Texture2D
	_select_button.tooltip_text = "Select (Q)"
	_select_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_select_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_select_button.toggle_mode = true
	_select_button.button_pressed = true
	_select_button.set_active_state(true)
	_select_button.pressed.connect(_on_select_tool_pressed)
	_toolbar_column.add_child(_select_button)

	# Shape Tool Button
	_shape_button = RoundIconButtonAtom.new()
	var box_icon_path: String = get_addon_base_path().path_join("assets/icons/icon_box.svg")
	if ResourceLoader.exists(box_icon_path):
		_shape_button.icon = load(box_icon_path) as Texture2D
	_shape_button.tooltip_text = "Shape: Box (B)"
	_shape_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_shape_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_shape_button.toggle_mode = true
	_shape_button.button_pressed = false
	_shape_button.set_active_state(false)
	_shape_button.pressed.connect(_on_shape_tool_pressed)
	_toolbar_column.add_child(_shape_button)

	# Shape Preset Flyout Molecule
	_shape_flyout = ShapeFlyoutContainer.new()
	_shape_flyout.name = "ShapePresetFlyout"
	_shape_flyout.position = Vector2(54, 88)
	_shape_flyout.populate_preset_buttons(Vector2(32, 32))
	_shape_flyout.visible = false
	_shape_flyout.on_primitive_selected.connect(_on_primitive_shape_selected)
	add_child(_shape_flyout)

	# Transform Status Bar (Floating bottom-center pill)
	_status_panel = PanelContainer.new()
	_status_panel.name = "TransformStatusPanel"
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_status_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_status_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_status_panel.offset_left = 0
	_status_panel.offset_right = 0
	_status_panel.offset_top = -24
	_status_panel.offset_bottom = -24
	_status_panel.visible = false

	var status_style := StyleBoxFlat.new()
	status_style.bg_color = Color(0.10, 0.12, 0.16, 0.94)
	status_style.border_color = Color(0.24, 0.28, 0.38, 0.85)
	status_style.set_border_width_all(1)
	status_style.set_corner_radius_all(8)
	status_style.content_margin_left = 16
	status_style.content_margin_right = 16
	status_style.content_margin_top = 8
	status_style.content_margin_bottom = 8
	_status_panel.add_theme_stylebox_override("panel", status_style)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_panel.add_child(_status_label)

	add_child(_status_panel)


func _on_transform_status_changed(status_text: String) -> void:
	if _status_panel == null or _status_label == null:
		return
	if status_text.is_empty():
		_status_panel.visible = false
	else:
		_status_label.text = status_text
		_status_panel.visible = true
		_status_panel.reset_size()



func _on_select_tool_pressed() -> void:
	_select_button.button_pressed = true
	_select_button.set_active_state(true)
	_shape_button.button_pressed = false
	_shape_button.set_active_state(false)
	if _shape_flyout != null:
		_shape_flyout.visible = false
	if editor_context != null:
		editor_context.active_tool = MapEditorContext.ToolMode.SELECT
	if editor_state_bus != null:
		editor_state_bus.emit_tool_changed(MapEditorContext.ToolMode.SELECT)


func _on_shape_tool_pressed() -> void:
	if editor_context != null and editor_context.active_tool == MapEditorContext.ToolMode.SHAPE:
		if _shape_flyout != null:
			_shape_flyout.visible = not _shape_flyout.visible
	else:
		_select_button.button_pressed = false
		_select_button.set_active_state(false)
		_shape_button.button_pressed = true
		_shape_button.set_active_state(true)
		if _shape_flyout != null:
			_shape_flyout.visible = true
		if editor_context != null:
			editor_context.active_tool = MapEditorContext.ToolMode.SHAPE
		if editor_state_bus != null:
			editor_state_bus.emit_tool_changed(MapEditorContext.ToolMode.SHAPE)


func _on_primitive_shape_selected(shape: ShapeFlyoutContainer.PrimitiveShape) -> void:
	var icon_path: String = ShapeFlyoutContainer.get_shape_icon_path(shape)
	if ResourceLoader.exists(icon_path):
		_shape_button.icon = load(icon_path) as Texture2D
	var shape_name: String = ShapeFlyoutContainer.get_shape_name(shape)
	_shape_button.tooltip_text = "Shape: " + shape_name + " (B)"

	if _shape_flyout != null:
		_shape_flyout.visible = false

	if editor_state_bus != null:
		editor_state_bus.emit_primitive_shape_changed(shape)


func _on_external_tool_changed(new_tool: int) -> void:
	if _select_button == null or _shape_button == null:
		return
	if new_tool == MapEditorContext.ToolMode.SELECT:
		_select_button.button_pressed = true
		_select_button.set_active_state(true)
		_shape_button.button_pressed = false
		_shape_button.set_active_state(false)
		if _shape_flyout != null:
			_shape_flyout.visible = false
	elif new_tool == MapEditorContext.ToolMode.SHAPE:
		_select_button.button_pressed = false
		_select_button.set_active_state(false)
		_shape_button.button_pressed = true
		_shape_button.set_active_state(true)


func select_tool(tool_mode: MapEditorContext.ToolMode) -> void:
	if tool_mode == MapEditorContext.ToolMode.SELECT:
		_on_select_tool_pressed()
	elif tool_mode == MapEditorContext.ToolMode.SHAPE:
		if editor_context == null or editor_context.active_tool != MapEditorContext.ToolMode.SHAPE:
			_on_shape_tool_pressed()


func toggle_shape_tool() -> void:
	_on_shape_tool_pressed()


func get_active_primitive() -> ShapeFlyoutContainer.PrimitiveShape:
	if _shape_flyout != null:
		return _shape_flyout.active_shape
	return ShapeFlyoutContainer.PrimitiveShape.BOX
