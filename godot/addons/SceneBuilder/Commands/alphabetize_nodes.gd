''' Alphabetize children of selected nodes.
		Nodes will be sorted together, at the top of the heirarchy
		Node3Ds will be sorted together, below any Nodes
'''

@tool
extends EditorPlugin

func execute():
	
	var editor : EditorInterface = get_editor_interface()
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action("Alphabetical Sort Children")
	
	var selection : EditorSelection = editor.get_selection()
	var selected_nodes : Array[Node] = selection.get_selected_nodes()

	for parent_node in selected_nodes:
		
		var children = parent_node.get_children()
		
		var names_to_nodes = {}
		var names_to_node3ds = {}
		var nodes_to_sort = {}
		
		for child in children:
			nodes_to_sort[child.name] = child
			if (child is Node3D):
				names_to_node3ds[child.name] = child
			else:
				names_to_nodes[child.name] = child
		
		# Sort
		var sorted_node_names = names_to_nodes.keys()
		var sorted_node3d_names = names_to_node3ds.keys()
		sorted_node_names.sort()
		sorted_node3d_names.sort()
		var sorted_names = sorted_node_names + sorted_node3d_names
		
		# Add methods
		for i in range(len(sorted_names)):
			var _name = sorted_names[i]
			var child_node = nodes_to_sort[_name]
			undo_redo.add_do_method(parent_node, "move_child", child_node, i)
			undo_redo.add_undo_method(parent_node, "move_child", child_node, parent_node.get_children().find(child_node))
		
		undo_redo.commit_action()
