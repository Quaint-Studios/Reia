@abstract
class_name MapEditorCommand
extends RefCounted

## Abstract base class for all reversible Map Editor operations.
## Subclasses must implement execute() and undo() for integration with EditorUndoRedoManager.

var action_name: String = "Map Edit"


func _init(p_action_name: String = "Map Edit") -> void:
	action_name = p_action_name


## Executes the command logic. Returns true if execution succeeded.
@abstract func execute() -> bool


## Reverses the command logic. Returns true if undo succeeded.
@abstract func undo() -> bool


## Returns the human-readable action label shown in the Godot Edit menu.
func get_action_name() -> String:
	return action_name


## Returns object references that should be tracked by EditorUndoRedoManager.add_do_reference.
func get_do_references() -> Array[Object]:
	return []
