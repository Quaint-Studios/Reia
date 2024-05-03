@tool
extends EditorPlugin

func execute():
	print("Making local...")
	
	if not Engine.is_editor_hint():
		return
	
	var editor: EditorInterface = get_editor_interface()
	var current_scene: Node = editor.get_edited_scene_root()
	var selection: Array[Node] = editor.get_selection().get_selected_nodes()
	
	if selection.is_empty():
		print("Selection is empty, returning")
		return
	
	for selected: Node3D in selection:
		MakeLocal(selected, current_scene)
	
	print("Saving and reloading scene from path...")
	editor.save_scene()
	editor.reload_scene_from_path(current_scene.scene_file_path)

func MakeLocal(node: Node3D, owner: Node):
	node.scene_file_path = ""
	node.owner = owner
	
	for childNode in node.get_children():
		childNode = MakeLocal(childNode, owner)
	
	return node

