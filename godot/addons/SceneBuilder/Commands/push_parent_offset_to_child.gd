''' Set selected node positions to 0,0,0 while preserving children's world positions. '''

@tool
extends EditorPlugin

func execute():
	
	var editor : EditorInterface = get_editor_interface()
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action("Push parent offset to child")

	var selection : EditorSelection = editor.get_selection()
	var selected_nodes : Array[Node] = selection.get_selected_nodes()
	
	for selected in selected_nodes:
		if selected is Node3D and selected.get_child_count() > 0:
			var parent : Node3D = selected
			var parent_position = parent.global_position

			var child_actions = []
			for _child in parent.get_children():
				if _child is Node3D:
					var child : Node3D = _child;
					var original_position = child.global_position
					child_actions.append([child, original_position])
	
			undo_redo.add_do_method(parent, "set_global_position", Vector3.ZERO)
			undo_redo.add_undo_method(parent, "set_global_position", parent.global_position)

			for action_data in child_actions:
				var child = action_data[0]
				var original_position = action_data[1]
				undo_redo.add_do_method(child, "set_global_position", original_position)
				undo_redo.add_undo_method(child, "set_global_position", original_position)

	undo_redo.commit_action()

