class_name MapEditorCommandHistory
extends RefCounted

## Manages reversible command execution.
## Wraps Godot's native EditorUndoRedoManager to support Ctrl+Z and Ctrl+Y in the editor.

var _undo_redo_manager: EditorUndoRedoManager = null
var _retained_commands: Array[MapEditorCommand] = []


func _init(undo_redo: EditorUndoRedoManager = null) -> void:
	_undo_redo_manager = undo_redo


## Executes a command and registers it with the native undo/redo stack.
func execute_command(command: MapEditorCommand) -> bool:
	if command == null:
		return false

	_retained_commands.append(command)
	if _retained_commands.size() > 200:
		_retained_commands.pop_front()

	if _undo_redo_manager == null:
		return command.execute()

	_undo_redo_manager.create_action(command.get_action_name())
	_undo_redo_manager.add_do_method(command, &"execute")
	_undo_redo_manager.add_undo_method(command, &"undo")
	_undo_redo_manager.add_do_reference(command)
	for ref in command.get_do_references():
		_undo_redo_manager.add_do_reference(ref)
	_undo_redo_manager.commit_action()
	return true
