@tool
extends EditorPlugin

func execute():
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	
	if selection.size() != 2:
		print("Exactly two nodes must be selected.")
		return
	
	var node_a = selection[0]
	var node_b = selection[1]
	
	# Check for parent-child relationship
	if node_a.get_parent() == node_b or node_b.get_parent() == node_a:
		print("The selected nodes cannot have a parent-child relationship.")
		return
	
	# Prepare for undo/redo
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Swap Positions and Rotations")
	
	# Swap positions
	undo_redo.add_do_method(node_a, "set_global_transform", node_b.global_transform)
	undo_redo.add_undo_method(node_a, "set_global_transform", node_a.global_transform)
	undo_redo.add_do_method(node_b, "set_global_transform", node_a.global_transform)
	undo_redo.add_undo_method(node_b, "set_global_transform", node_b.global_transform)
	
	# Swap rotations
	undo_redo.add_do_method(node_a, "set_rotation", node_b.rotation)
	undo_redo.add_undo_method(node_a, "set_rotation", node_a.rotation)
	undo_redo.add_do_method(node_b, "set_rotation", node_a.rotation)
	undo_redo.add_undo_method(node_b, "set_rotation", node_b.rotation)
	
	undo_redo.commit_action()
