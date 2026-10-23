@tool
extends EditorPlugin

## Map Editor entrypoint.

const SETTING_ACTIVE_STATE: String = "map_editor/general/active_state"

var editor_context: MapEditorContext = null
var editor_state_bus: MapEditorStateBus = null
var command_history: MapEditorCommandHistory = null
var overlay_mount_manager: OverlayMountManager = null
var input_router: EditorInputRouter = null
var active_toggle_button: MapEditorActiveToggle = null


func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()


func _enter_tree() -> void:
	set_input_event_forwarding_always_enabled()
	set_physics_process(true)
	_initialize_core_systems()


func _exit_tree() -> void:
	_teardown_core_systems()


func _initialize_core_systems() -> void:
	editor_context = MapEditorContext.new()
	editor_context.is_active = _get_persisted_active_state()
	editor_state_bus = MapEditorStateBus.new()
	editor_state_bus.on_active_state_changed.connect(_on_active_state_changed)
	command_history = MapEditorCommandHistory.new(get_undo_redo())

	# Create and mount spatial editor menu toggle button
	var icon_path := get_plugin_path().path_join("assets/icons/icon_shape.svg")
	var icon_tex: Texture2D = load(icon_path) if ResourceLoader.exists(icon_path) else null
	active_toggle_button = MapEditorActiveToggle.new()
	active_toggle_button.setup(editor_context, editor_state_bus, icon_tex)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, active_toggle_button)

	overlay_mount_manager = OverlayMountManager.new(get_plugin_path())
	overlay_mount_manager.mount(editor_context, editor_state_bus)

	input_router = EditorInputRouter.new()
	input_router.setup(editor_context, editor_state_bus, command_history)


func _teardown_core_systems() -> void:
	set_physics_process(false)

	if active_toggle_button != null:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, active_toggle_button)
		active_toggle_button.queue_free()
		active_toggle_button = null

	if input_router != null:
		input_router.teardown()
		input_router = null

	if overlay_mount_manager != null:
		overlay_mount_manager.teardown()
		overlay_mount_manager = null

	if editor_state_bus != null and editor_state_bus.on_active_state_changed.is_connected(_on_active_state_changed):
		editor_state_bus.on_active_state_changed.disconnect(_on_active_state_changed)

	editor_context = null
	editor_state_bus = null
	command_history = null


func _get_persisted_active_state() -> bool:
	var settings := EditorInterface.get_editor_settings()
	if settings != null and settings.has_setting(SETTING_ACTIVE_STATE):
		return settings.get_setting(SETTING_ACTIVE_STATE)
	return true


func _persist_active_state(p_active: bool) -> void:
	var settings := EditorInterface.get_editor_settings()
	if settings != null:
		settings.set_setting(SETTING_ACTIVE_STATE, p_active)


func _on_active_state_changed(is_active: bool) -> void:
	_persist_active_state(is_active)


func _handles(_object: Object) -> bool:
	return false


func _physics_process(delta: float) -> void:
	if input_router != null:
		input_router.process_physics(delta)


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if input_router != null:
		return input_router.forward_3d_gui_input(viewport_camera, event)
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func get_editor_context() -> MapEditorContext:
	return editor_context


func get_editor_state_bus() -> MapEditorStateBus:
	return editor_state_bus


func get_command_history() -> MapEditorCommandHistory:
	return command_history


func get_overlay_mount_manager() -> OverlayMountManager:
	return overlay_mount_manager


func get_viewport_overlay() -> MapViewportOverlay:
	if overlay_mount_manager != null:
		return overlay_mount_manager.get_overlay()
	return null


func get_input_router() -> EditorInputRouter:
	return input_router
