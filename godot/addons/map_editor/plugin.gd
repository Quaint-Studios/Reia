@tool
extends EditorPlugin

## Map Editor plugin lifecycle entrypoint.
## Scopes editor context, event bus, and undo/redo handling without global autoloads.

var editor_context: MapEditorContext = null
var editor_state_bus: MapEditorStateBus = null
var command_history: MapEditorCommandHistory = null
var viewport_overlay: MapViewportOverlay = null


func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()


func _enter_tree() -> void:
	_initialize_core_systems()


func _exit_tree() -> void:
	_teardown_core_systems()


func _initialize_core_systems() -> void:
	editor_context = MapEditorContext.new()
	editor_state_bus = MapEditorStateBus.new()
	command_history = MapEditorCommandHistory.new(get_undo_redo())
	_mount_viewport_overlay()


func _find_3d_viewport_control() -> Control:
	var vp: SubViewport = EditorInterface.get_editor_viewport_3d(0)
	if vp == null:
		return null
	var parent: Node = vp.get_parent()
	if parent == null:
		return null
	if parent.get_parent() is Control:
		return parent.get_parent() as Control
	if parent is Control:
		return parent as Control
	return null


func _mount_viewport_overlay() -> void:
	var vp_control: Control = _find_3d_viewport_control()
	if vp_control == null:
		_mount_viewport_overlay.call_deferred()
		return

	# Remove any lingering overlay instance from hot-reloads
	var existing: Node = vp_control.get_node_or_null("MapEditorViewportOverlay")
	if existing != null:
		vp_control.remove_child(existing)
		existing.queue_free()

	viewport_overlay = MapViewportOverlay.new()
	viewport_overlay.setup(editor_context, editor_state_bus)
	vp_control.add_child(viewport_overlay)


func _teardown_core_systems() -> void:
	if viewport_overlay != null:
		if viewport_overlay.get_parent() != null:
			viewport_overlay.get_parent().remove_child(viewport_overlay)
		viewport_overlay.queue_free()
		viewport_overlay = null

	var vp_control: Control = _find_3d_viewport_control()
	if vp_control != null:
		var lingering: Node = vp_control.get_node_or_null("MapEditorViewportOverlay")
		if lingering != null:
			vp_control.remove_child(lingering)
			lingering.queue_free()

	editor_context = null
	editor_state_bus = null
	command_history = null


func get_editor_context() -> MapEditorContext:
	return editor_context


func get_editor_state_bus() -> MapEditorStateBus:
	return editor_state_bus


func get_command_history() -> MapEditorCommandHistory:
	return command_history
