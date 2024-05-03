@tool
extends EditorPlugin

func execute(_spacing : int):
	var selected_paths = get_editor_interface().get_selected_paths()
	
	var x_offset = 0
	var scenes_instantiated = 0

	var editor = get_editor_interface()
	var current_scene = editor.get_edited_scene_root()

	if current_scene == null:
		return
	
	var instantiated_nodes = []
	
	for path in selected_paths:
		if ResourceLoader.exists(path) and load(path) is PackedScene:
			var scene = load(path) as PackedScene
			var instance = scene.instantiate()
			
			var suffix = 1
			var base_name = instance.name
			
			if base_name.ends_with("-n" + str(suffix)):
				var parts = base_name.split("-n")
				if parts.size() > 1:
					base_name = parts[0]
				else:
					print("Unexpected format.")
			else:
				instance.name += "-n1"
			
			while current_scene.has_node(NodePath(instance.name)):
				suffix += 1
				instance.name = str(base_name) + "-n" + str(suffix)
			
			current_scene.add_child(instance)
			instantiated_nodes.append(instance)
			instance.owner = current_scene
			instance.global_transform.origin = Vector3(x_offset, 0, 0)
			x_offset += _spacing
			scenes_instantiated += 1
			
			print("Instantiated: " + instance.name)
	
	var selection = editor.get_selection()
	selection.clear()

	for node in instantiated_nodes:
		selection.add_node(node)

