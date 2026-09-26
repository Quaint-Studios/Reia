@tool
extends EditorPlugin

## Map Editor plugin lifecycle entrypoint.
## Scopes editor context, event bus, and undo/redo handling without global autoloads.

var editor_context: RefCounted = null
var editor_state_bus: RefCounted = null
var command_history: RefCounted = null


func _enter_tree() -> void:
	_initialize_core_systems()


func _exit_tree() -> void:
	_teardown_core_systems()


func _initialize_core_systems() -> void:
	editor_context = MapEditorContext.new()
	editor_state_bus = MapEditorStateBus.new()
	command_history = MapEditorCommandHistory.new(get_undo_redo())


func _teardown_core_systems() -> void:
	editor_context = null
	editor_state_bus = null
	command_history = null


func get_editor_context() -> RefCounted:
	return editor_context


func get_editor_state_bus() -> RefCounted:
	return editor_state_bus


func get_command_history() -> RefCounted:
	return command_history
