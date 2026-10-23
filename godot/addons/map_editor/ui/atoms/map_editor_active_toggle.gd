@tool
class_name MapEditorActiveToggle
extends Button

## Atom button mounted to Godot's 3D viewport spatial editor menu (CONTAINER_SPATIAL_EDITOR_MENU).
## Provides an icon-only toggle with dynamic tooltip and accent color modulation.

const SHORTCUT_TEXT: String = "Alt+M"

# Icon Colors
const ICON_ACTIVE_COLOR: Color = Color(60.0 / 255.0, 155.0 / 255.0, 1.0, 1.0) # rgb(60, 155, 255) vibrant rich blue
const ICON_ACTIVE_HOVER_COLOR: Color = Color(85.0 / 255.0, 175.0 / 255.0, 1.0, 1.0)
const ICON_ACTIVE_PRESSED_COLOR: Color = Color(60.0 / 255.0, 155.0 / 255.0, 1.0, 1.0)
const ICON_ACTIVE_HOVER_PRESSED_COLOR: Color = Color(85.0 / 255.0, 175.0 / 255.0, 1.0, 1.0)

const ICON_INACTIVE_COLOR: Color = Color(0.75, 0.80, 0.88, 0.7)
const ICON_INACTIVE_HOVER_COLOR: Color = Color(0.92, 0.95, 1.0, 1.0)
const ICON_INACTIVE_PRESSED_COLOR: Color = Color(0.75, 0.80, 0.88, 0.7)
const ICON_INACTIVE_HOVER_PRESSED_COLOR: Color = Color(0.92, 0.95, 1.0, 1.0)

# StyleBox Background Fallbacks
const BG_HOVER_FALLBACK: Color = Color(1.0, 1.0, 1.0, 0.12)
const BG_PRESSED_FALLBACK: Color = Color(1.0, 1.0, 1.0, 0.18)
const BG_HOVER_PRESSED_FALLBACK: Color = Color(1.0, 1.0, 1.0, 0.24)

var editor_context: MapEditorContext = null
var editor_state_bus: MapEditorStateBus = null
var _raw_icon_texture: Texture2D = null
var _is_updating: bool = false


func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	theme_type_variation = &"FlatButton"
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	toggled.connect(_on_button_toggled)


func _ready() -> void:
	_setup_editor_styles()
	if _raw_icon_texture != null:
		_apply_scaled_icon(_raw_icon_texture)


func setup(context: MapEditorContext, state_bus: MapEditorStateBus, icon_texture: Texture2D) -> void:
	editor_context = context
	editor_state_bus = state_bus
	_raw_icon_texture = icon_texture

	_setup_editor_styles()
	if _raw_icon_texture != null:
		_apply_scaled_icon(_raw_icon_texture)

	if editor_state_bus != null:
		if not editor_state_bus.on_active_state_changed.is_connected(_on_external_active_state_changed):
			editor_state_bus.on_active_state_changed.connect(_on_external_active_state_changed)

	var current_active: bool = editor_context.is_active if editor_context != null else true
	set_pressed_no_signal(current_active)
	_update_visuals(current_active)


func _setup_editor_styles() -> void:
	if _is_updating:
		return
	_is_updating = true

	if Engine.is_editor_hint():
		var base := EditorInterface.get_base_control()
		if base != null:
			var normal_sb: StyleBox = base.get_theme_stylebox(&"normal", &"FlatButton") if base.has_theme_stylebox(&"normal", &"FlatButton") else StyleBoxEmpty.new()

			var hover_sb: StyleBox = null
			if base.has_theme_stylebox(&"hover", &"FlatButton"):
				hover_sb = base.get_theme_stylebox(&"hover", &"FlatButton")
			elif base.has_theme_stylebox(&"hover", &"Button"):
				hover_sb = base.get_theme_stylebox(&"hover", &"Button")

			if hover_sb == null or (hover_sb is StyleBoxFlat and (hover_sb as StyleBoxFlat).bg_color.a < 0.02):
				var fallback_hover := StyleBoxFlat.new()
				fallback_hover.bg_color = BG_HOVER_FALLBACK
				fallback_hover.set_corner_radius_all(3)
				hover_sb = fallback_hover

			var pressed_sb: StyleBox = null
			if base.has_theme_stylebox(&"pressed", &"FlatButton"):
				pressed_sb = base.get_theme_stylebox(&"pressed", &"FlatButton")
			elif base.has_theme_stylebox(&"pressed", &"Button"):
				pressed_sb = base.get_theme_stylebox(&"pressed", &"Button")

			if pressed_sb == null or (pressed_sb is StyleBoxFlat and (pressed_sb as StyleBoxFlat).bg_color.a < 0.02):
				var fallback_pressed := StyleBoxFlat.new()
				fallback_pressed.bg_color = BG_PRESSED_FALLBACK
				fallback_pressed.set_corner_radius_all(3)
				pressed_sb = fallback_pressed

			var hover_pressed_sb: StyleBox = null
			if base.has_theme_stylebox(&"hover_pressed", &"FlatButton"):
				hover_pressed_sb = base.get_theme_stylebox(&"hover_pressed", &"FlatButton")
			elif base.has_theme_stylebox(&"hover_pressed", &"Button"):
				hover_pressed_sb = base.get_theme_stylebox(&"hover_pressed", &"Button")

			if hover_pressed_sb == null:
				var fallback_hp := StyleBoxFlat.new()
				fallback_hp.bg_color = BG_HOVER_PRESSED_FALLBACK
				fallback_hp.set_corner_radius_all(3)
				hover_pressed_sb = fallback_hp

			add_theme_stylebox_override(&"normal", normal_sb)
			add_theme_stylebox_override(&"hover", hover_sb)
			add_theme_stylebox_override(&"pressed", pressed_sb)
			add_theme_stylebox_override(&"hover_pressed", hover_pressed_sb)

	_is_updating = false


func _on_button_toggled(pressed_state: bool) -> void:
	if editor_context != null:
		editor_context.is_active = pressed_state
	_update_visuals(pressed_state)
	if editor_state_bus != null:
		editor_state_bus.emit_active_state_changed(pressed_state)


func _on_external_active_state_changed(p_active: bool) -> void:
	if button_pressed != p_active:
		set_pressed_no_signal(p_active)
	_update_visuals(p_active)


func _update_visuals(p_active: bool) -> void:
	if _is_updating:
		return
	_is_updating = true

	self_modulate = Color.WHITE
	if p_active:
		tooltip_text = "Map Editor: Active (%s)" % SHORTCUT_TEXT
		add_theme_color_override(&"icon_normal_color", ICON_ACTIVE_COLOR)
		add_theme_color_override(&"icon_hover_color", ICON_ACTIVE_HOVER_COLOR)
		add_theme_color_override(&"icon_pressed_color", ICON_ACTIVE_PRESSED_COLOR)
		add_theme_color_override(&"icon_hover_pressed_color", ICON_ACTIVE_HOVER_PRESSED_COLOR)
	else:
		tooltip_text = "Map Editor: Inactive (%s)" % SHORTCUT_TEXT
		add_theme_color_override(&"icon_normal_color", ICON_INACTIVE_COLOR)
		add_theme_color_override(&"icon_hover_color", ICON_INACTIVE_HOVER_COLOR)
		add_theme_color_override(&"icon_pressed_color", ICON_INACTIVE_PRESSED_COLOR)
		add_theme_color_override(&"icon_hover_pressed_color", ICON_INACTIVE_HOVER_PRESSED_COLOR)

	_is_updating = false


func _get_toolbar_icon_size() -> Vector2:
	if Engine.is_editor_hint():
		var base_control := EditorInterface.get_base_control()
		if base_control != null:
			if base_control.has_theme_icon(&"ToolSelect", &"EditorIcons"):
				return base_control.get_theme_icon(&"ToolSelect", &"EditorIcons").get_size()
			if base_control.has_theme_icon(&"Node3D", &"EditorIcons"):
				return base_control.get_theme_icon(&"Node3D", &"EditorIcons").get_size()
		var ed_scale := EditorInterface.get_editor_scale()
		return Vector2(16.0, 16.0) * ed_scale
	return Vector2(16.0, 16.0)


func _apply_scaled_icon(p_icon: Texture2D) -> void:
	if p_icon == null:
		icon = null
		return

	var target_size := _get_toolbar_icon_size()
	var img := p_icon.get_image()
	if img != null and not img.is_empty():
		var tw: int = roundi(target_size.x)
		var th: int = roundi(target_size.y)
		if img.get_width() != tw or img.get_height() != th:
			var resized_img := img.duplicate()
			resized_img.resize(tw, th, Image.INTERPOLATE_LANCZOS)
			icon = ImageTexture.create_from_image(resized_img)
			return

	icon = p_icon
