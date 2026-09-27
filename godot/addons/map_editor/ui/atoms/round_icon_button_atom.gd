@tool
class_name RoundIconButtonAtom
extends Button

## Reusable rounded icon button atom.
## Features rounded corners, inner content padding, and clean border-only active highlighting.

@export var button_size: Vector2 = Vector2(36, 36):
	set(val):
		button_size = val
		_update_styles()

@export var corner_radius: int = 8:
	set(val):
		corner_radius = val
		_update_styles()

@export var padding: int = 8:
	set(val):
		padding = val
		_update_styles()

@export var is_active: bool = false:
	set(val):
		is_active = val
		_update_styles()

# Theme Colors
var normal_bg: Color = Color(0.12, 0.13, 0.16, 0.95) # #1f2129f2
var hover_bg: Color = Color(0.18, 0.20, 0.25, 1.0) # #2e3340
var pressed_bg: Color = Color(0.09, 0.10, 0.12, 1.0) # #171a1f
var active_bg: Color = Color(0.12, 0.22, 0.35, 1.0) # #1f3859

var border_normal: Color = Color(0.24, 0.27, 0.33, 0.8) # #3d4554cc
var border_hover: Color = Color(0.38, 0.43, 0.52, 1.0) # #616e85
var border_active: Color = Color(0.25, 0.55, 0.95, 1.0) # #408cf2 (Active Blue)

# Icons
var icon_normal_tint: Color = Color(0.85, 0.88, 0.92, 1.0)
var icon_hover_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

var _is_updating: bool = false


func _init() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	toggled.connect(_on_toggled)


func _on_toggled(toggled_on: bool) -> void:
	is_active = toggled_on


func _ready() -> void:
	_update_styles()


func set_active_state(active: bool) -> void:
	is_active = active


func _update_styles() -> void:
	if _is_updating:
		return
	_is_updating = true

	custom_minimum_size = button_size

	# Normal StyleBox
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = normal_bg
	style_normal.border_color = border_active if is_active else border_normal
	style_normal.set_border_width_all(2 if is_active else 1)
	style_normal.set_corner_radius_all(corner_radius)
	style_normal.content_margin_left = padding
	style_normal.content_margin_top = padding
	style_normal.content_margin_right = padding
	style_normal.content_margin_bottom = padding
	style_normal.anti_aliasing = true

	# Hover StyleBox
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = hover_bg
	style_hover.border_color = border_active.lightened(0.2) if is_active else border_hover
	style_hover.set_border_width_all(2 if is_active else 1)
	style_hover.set_corner_radius_all(corner_radius)
	style_hover.content_margin_left = padding
	style_hover.content_margin_top = padding
	style_hover.content_margin_right = padding
	style_hover.content_margin_bottom = padding
	style_hover.anti_aliasing = true

	# Pressed StyleBox
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = normal_bg
	style_pressed.border_color = border_active if is_active else border_normal
	style_pressed.set_border_width_all(2 if is_active else 1)
	style_pressed.set_corner_radius_all(corner_radius)
	style_pressed.content_margin_left = padding
	style_pressed.content_margin_top = padding
	style_pressed.content_margin_right = padding
	style_pressed.content_margin_bottom = padding
	style_pressed.anti_aliasing = true

	# Hover Pressed StyleBox
	var style_hover_pressed := StyleBoxFlat.new()
	style_hover_pressed.bg_color = hover_bg
	style_hover_pressed.border_color = border_active.lightened(0.2) if is_active else border_hover
	style_hover_pressed.set_border_width_all(2 if is_active else 1)
	style_hover_pressed.set_corner_radius_all(corner_radius)
	style_hover_pressed.content_margin_left = padding
	style_hover_pressed.content_margin_top = padding
	style_hover_pressed.content_margin_right = padding
	style_hover_pressed.content_margin_bottom = padding
	style_hover_pressed.anti_aliasing = true

	# Focus StyleBox
	var style_focus := StyleBoxEmpty.new()

	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("hover_pressed", style_hover_pressed)
	add_theme_stylebox_override("focus", style_focus)

	# Icon colors
	add_theme_color_override("icon_normal_color", icon_normal_tint)
	add_theme_color_override("icon_hover_color", icon_hover_tint)
	add_theme_color_override("icon_pressed_color", icon_normal_tint if is_active else icon_hover_tint)
	add_theme_color_override("icon_hover_pressed_color", icon_hover_tint)
	add_theme_color_override("icon_focus_color", icon_normal_tint)

	_is_updating = false
