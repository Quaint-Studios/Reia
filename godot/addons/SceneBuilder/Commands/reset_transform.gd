''' Sets selected nodes' position, rotation, and scale to initial values. '''

@tool
extends EditorPlugin

func execute():
	
	var editor : EditorInterface = get_editor_interface()
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action("Reset node name")
	
	var current_scene : Node = editor.get_edited_scene_root()
	var selection : EditorSelection = editor.get_selection()
	var selected_nodes : Array[Node] = selection.get_selected_nodes()

	for selected: Node3D in selected_nodes:
		
		undo_redo.add_do_method(selected, "set_position", Vector3(0, 0, 0))
		undo_redo.add_undo_method(selected, "set_position", selected.position)
		
		undo_redo.add_do_method(selected, "set_rotation_degrees", Vector3(0, 0, 0))
		undo_redo.add_undo_method(selected, "set_rotation_degrees", selected.rotation_degrees)
		
		undo_redo.add_do_method(selected, "set_scale", Vector3(1, 1, 1))
		undo_redo.add_undo_method(selected, "set_scale", selected.scale)

	undo_redo.commit_action()
