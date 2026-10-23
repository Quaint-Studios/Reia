@tool
class_name MapEditorActiveToggle
extends Button

## Atom button mounted to Godot's 3D viewport spatial editor menu (CONTAINER_SPATIAL_EDITOR_MENU).
## Provides an icon-only toggle with dynamic tooltip and accent color modulation.

const SHORTCUT_TEXT: String = "Alt+M"
const ACTIVE_TINT: Color = Color(0.25, 0.85, 1.0, 1.0)
const INACTIVE_TINT: Color = Color(0.75, 0.80, 0.90, 0.7)

var editor_context: MapEditorContext = null
var editor_state_bus: MapEditorStateBus = null


func _init() -> void:
	flat = true
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggled.connect(_on_button_toggled)


func setup(context: MapEditorContext, state_bus: MapEditorStateBus, icon_texture: Texture2D) -> void:
	editor_context = context
	editor_state_bus = state_bus

	if icon_texture != null:
		icon = icon_texture

	if editor_state_bus != null:
		if not editor_state_bus.on_active_state_changed.is_connected(_on_external_active_state_changed):
			editor_state_bus.on_active_state_changed.connect(_on_external_active_state_changed)

	var current_active: bool = editor_context.is_active if editor_context != null else true
	set_pressed_no_signal(current_active)
	_update_visuals(current_active)


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
	if p_active:
		tooltip_text = "Map Editor: Active (%s)" % SHORTCUT_TEXT
		self_modulate = ACTIVE_TINT
	else:
		tooltip_text = "Map Editor: Inactive (%s)" % SHORTCUT_TEXT
		self_modulate = INACTIVE_TINT
