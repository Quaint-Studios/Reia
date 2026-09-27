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


func _init() -> void:
	name = "MapEditorViewportOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(10, 46)


func setup(context: MapEditorContext, state_bus: MapEditorStateBus) -> void:
	editor_context = context
	editor_state_bus = state_bus


func _ready() -> void:
	_build_ui()


func get_addon_base_path() -> String:
	return (get_script() as Script).resource_path.get_base_dir().get_base_dir().get_base_dir()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# Main vertical toolbar column
	_toolbar_column = VBoxContainer.new()
	_toolbar_column.name = "ToolbarColumn"
	_toolbar_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_shape_flyout.position = Vector2(44, 42)
	_shape_flyout.populate_preset_buttons(Vector2(32, 32))
	_shape_flyout.visible = false
	_shape_flyout.on_primitive_selected.connect(_on_primitive_shape_selected)
	add_child(_shape_flyout)


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


func get_active_primitive() -> ShapeFlyoutContainer.PrimitiveShape:
	if _shape_flyout != null:
		return _shape_flyout.active_shape
	return ShapeFlyoutContainer.PrimitiveShape.BOX
