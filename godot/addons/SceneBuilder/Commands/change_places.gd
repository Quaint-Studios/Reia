''' If exactly two Node3Ds are selected in Scene, then swap their positions 
	and rotations. '''

@tool
extends EditorPlugin

func execute():
	
	var editor : EditorInterface = get_editor_interface()
	
	var current_scene : Node = editor.get_edited_scene_root()
	var selection : EditorSelection = editor.get_selection()
	var selected_nodes : Array[Node] = selection.get_selected_nodes()
	
	if selected_nodes.size() != 2:
		print("Exactly two nodes must be selected.")
		return
	
	var node_a = selected_nodes[0]
	var node_b = selected_nodes[1]
	
	if not node_a is Node3D or not node_b is Node3D:
		return
	
	# Check for parent-child relationship
	if node_a.get_parent() == node_b or node_b.get_parent() == node_a:
		print("The selected nodes cannot have a parent-child relationship.")
		return
	
	# Set-up undo_redo
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
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
