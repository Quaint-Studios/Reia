@tool
extends EditorPlugin

func execute():
	
	var selection: EditorSelection = get_editor_interface().get_selection()
	#var new_transform: Transform3D = Transform3D()
	
	#new_transform.origin = Vector3(0, 0, 0)
	#new_transform.basis = Basis()
	
	for selected: Node3D in selection.get_selected_nodes():
		#selected.global_transform = new_transform
		
		selected.position = Vector3(0, 0, 0)
		selected.rotation = Vector3(0, 0, 0)
		selected.scale = Vector3(1, 1, 1)

