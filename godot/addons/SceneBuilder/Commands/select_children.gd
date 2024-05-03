@tool
extends EditorPlugin

func execute():
	var selection = get_editor_interface().get_selection().get_selected_nodes()
	
	if selection.is_empty():
		print("Selection is empty")
		return
		
	get_editor_interface().get_selection().clear()

	for node in selection:
		for child in node.get_children():
			get_editor_interface().get_selection().add_node(child)

