@tool
extends EditorPlugin

func execute():
	var toolbox : SceneBuilderToolbox = SceneBuilderToolbox.new()
	
	var editor = get_editor_interface()
	var editor_selection = editor.get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()

	var all_names = toolbox.get_all_node_names(get_editor_interface().get_edited_scene_root())
	
	var pattern = "\\w -n(\\d+)"
	var regex = RegEx.new()
	regex.compile(pattern)
	
	for node in selected_nodes:
		
		all_names = toolbox.get_all_node_names(get_editor_interface().get_edited_scene_root())
		
		if node.scene_file_path:
			var path_name = node.scene_file_path.get_file().get_basename()
			
			node.name = toolbox.increment_name_until_unique(path_name, all_names)
			
		else:
			print("Passing over: " + node.name)
