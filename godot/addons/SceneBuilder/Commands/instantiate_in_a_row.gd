''' Used to layout new assets in a row, a simple but often helpful task. '''

@tool
extends EditorPlugin

func execute(_spacing : int):
	
	var editor : EditorInterface = get_editor_interface()
	var undo_redo : EditorUndoRedoManager = get_undo_redo()
	undo_redo.create_action("Instantiate Scenes")
	
	var current_scene : Node = editor.get_edited_scene_root()
	var selected_paths : PackedStringArray = editor.get_selected_paths()
	
	if current_scene == null:
		return
	
	var instantiated_nodes = []
	var x_offset = 0
	 
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
			
			undo_redo.add_do_method(current_scene, "add_child", instance)
			undo_redo.add_do_method(instance, "set_owner", current_scene)
			undo_redo.add_do_method(instance, "set_global_position", Vector3(x_offset, 0, 0))
			undo_redo.add_undo_method(current_scene, "remove_child", instance)
			instantiated_nodes.append(instance)
			x_offset += _spacing
			
			print("Instantiated: " + instance.name)
	
	undo_redo.commit_action()
	
	var selection = editor.get_selection()
	selection.clear()
	
	# Select newly instantiated nodes
	for node in instantiated_nodes:
		selection.add_node(node)
