@tool
class_name ShapeFlyoutContainer
extends PanelContainer

## Horizontal flyout container molecule for shape primitive presets.
## Houses procedural primitive buttons with icons, active state toggling, and clean styling.

enum PrimitiveShape {
	BOX,
	SPHERE,
	CYLINDER,
	PYRAMID,
	WEDGE,
	CAPSULE,
}

signal on_primitive_selected(shape: PrimitiveShape)

const SHAPE_DATA: Array[Dictionary] = [
	{
		"type": PrimitiveShape.BOX,
		"name": "Box",
		"tooltip": "Box / Cube",
		"icon_filename": "icon_box.svg"
	},
	{
		"type": PrimitiveShape.SPHERE,
		"name": "Sphere",
		"tooltip": "Sphere",
		"icon_filename": "icon_sphere.svg"
	},
	{
		"type": PrimitiveShape.CYLINDER,
		"name": "Cylinder",
		"tooltip": "Cylinder",
		"icon_filename": "icon_cylinder.svg"
	},
	{
		"type": PrimitiveShape.PYRAMID,
		"name": "Pyramid",
		"tooltip": "Pyramid",
		"icon_filename": "icon_pyramid.svg"
	},
	{
		"type": PrimitiveShape.WEDGE,
		"name": "Wedge",
		"tooltip": "Wedge / Ramp",
		"icon_filename": "icon_wedge.svg"
	},
	{
		"type": PrimitiveShape.CAPSULE,
		"name": "Capsule",
		"tooltip": "Capsule",
		"icon_filename": "icon_capsule.svg"
	}
]

@export var corner_radius: int = 8:
	set(val):
		corner_radius = val
		_update_style()

@export var padding: int = 4:
	set(val):
		padding = val
		_update_style()

@export var item_separation: int = 6:
	set(val):
		item_separation = val
		if _row != null:
			_row.add_theme_constant_override("separation", item_separation)

@export var bg_color: Color = Color(0.09, 0.10, 0.13, 0.95): # #171a21f2
	set(val):
		bg_color = val
		_update_style()

@export var border_color: Color = Color(0.24, 0.27, 0.33, 0.8): # #3d4554cc
	set(val):
		border_color = val
		_update_style()

var active_shape: PrimitiveShape = PrimitiveShape.BOX
var _row: HBoxContainer = null
var _buttons: Array[RoundIconButtonAtom] = []
var _button_group: ButtonGroup = null
var _is_updating: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_internal_row()


func _ready() -> void:
	_update_style()
	if _row != null and _row.get_child_count() == 0:
		populate_preset_buttons()


func _setup_internal_row() -> void:
	if _row == null:
		_row = HBoxContainer.new()
		_row.name = "PresetsRow"
		_row.mouse_filter = Control.MOUSE_FILTER_PASS
		_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_row.add_theme_constant_override("separation", item_separation)
		add_child(_row)


func get_row_container() -> HBoxContainer:
	if _row == null:
		_setup_internal_row()
	return _row


func populate_preset_buttons(button_size: Vector2 = Vector2(32, 32)) -> void:
	var row := get_row_container()
	for child in row.get_children():
		child.queue_free()
	_buttons.clear()

	_button_group = ButtonGroup.new()
	_button_group.allow_unpress = false

	for i in range(SHAPE_DATA.size()):
		var data: Dictionary = SHAPE_DATA[i]
		var shape_type: PrimitiveShape = data["type"] as PrimitiveShape
		var btn := RoundIconButtonAtom.new()
		btn.name = "Btn_" + str(data["name"])
		btn.button_size = button_size
		btn.corner_radius = 6
		btn.padding = 6
		btn.tooltip_text = str(data["tooltip"])
		btn.toggle_mode = true
		btn.button_group = _button_group

		var icon_path: String = get_shape_icon_path(shape_type)
		if ResourceLoader.exists(icon_path):
			btn.icon = load(icon_path) as Texture2D

		var is_selected: bool = (shape_type == active_shape)
		btn.button_pressed = is_selected
		btn.set_active_state(is_selected)

		btn.toggled.connect(func(toggled_on: bool) -> void:
			btn.set_active_state(toggled_on)
			if toggled_on:
				active_shape = shape_type
				on_primitive_selected.emit(shape_type)
				visible = false
		)
		btn.pressed.connect(func() -> void:
			active_shape = shape_type
			on_primitive_selected.emit(shape_type)
			visible = false
		)

		row.add_child(btn)
		_buttons.append(btn)


static func get_plugin_path() -> String:
	var script_path: String = (ShapeFlyoutContainer as Script).resource_path
	var marker: String = "/addons/map_editor"
	var idx: int = script_path.find(marker)
	if idx != -1:
		return script_path.substr(0, idx + marker.length())
	return (ShapeFlyoutContainer as Script).resource_path.get_base_dir().get_base_dir().get_base_dir()


static func get_addon_base_path() -> String:
	return get_plugin_path()


static func get_shape_icon_filename(shape: PrimitiveShape) -> String:
	for data in SHAPE_DATA:
		if (data["type"] as PrimitiveShape) == shape:
			return str(data["icon_filename"])
	return "icon_box.svg"


static func get_shape_icon_path(shape: PrimitiveShape) -> String:
	return get_addon_base_path().path_join("assets/icons").path_join(get_shape_icon_filename(shape))


static func get_shape_name(shape: PrimitiveShape) -> String:
	for data in SHAPE_DATA:
		if (data["type"] as PrimitiveShape) == shape:
			return str(data["name"])
	return "Box"


func select_shape(shape: PrimitiveShape) -> void:
	active_shape = shape
	for i in range(SHAPE_DATA.size()):
		if (SHAPE_DATA[i]["type"] as PrimitiveShape) == shape and i < _buttons.size():
			_buttons[i].button_pressed = true


func _update_style() -> void:
	if _is_updating:
		return
	_is_updating = true

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	style.anti_aliasing = true

	add_theme_stylebox_override("panel", style)

	if _row != null:
		_row.add_theme_constant_override("separation", item_separation)

	_is_updating = false
