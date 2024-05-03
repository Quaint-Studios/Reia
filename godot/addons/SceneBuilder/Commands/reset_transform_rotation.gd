@tool
extends EditorPlugin

func execute():
	
	var selection: EditorSelection = get_editor_interface().get_selection()
	
	for selected: Node3D in selection.get_selected_nodes():
		selected.rotation = Vector3(0, 0, 0)

