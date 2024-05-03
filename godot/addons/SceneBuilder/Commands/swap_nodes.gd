@tool
extends EditorPlugin

var utilities = load("res://addons/EditorToolbox/editor_toolbox_utilities.gd")

func execute():
	"""
	Replaces each selected node in the Scene with an instance of the selected 
	PackedScene from the FileSystem. 
	
	The instantiated PackedScene inherits transform information from the node it
	replaces. Exactly one PackedScene should be selected in the FileSystem and 
	at least one node should be selected in the Scene.
	
	Note: We are currently assuming that all PackedScenes have a root Node3D.
	"""
	
	var editor = get_editor_interface()
	var selected_paths = editor.get_selected_paths()
	var selected_nodes = editor.get_selection().get_selected_nodes()

	#region Verify selection
	
	# Only one item should be selected in the Filesystem
	if selected_paths.size() != 1:
		print("Error: Please select exactly one PackedScene in the FileSystem.")
		return
	
	# Selected Filesystem item must be a PackedScene
	var selected_path = selected_paths[0]
	var resource = load(selected_path)
	if not resource or not resource is PackedScene:
		print("Error: The selected path is not a PackedScene.")
		return
	
	# Verify Scene selection
	if selected_nodes.is_empty():
		print("Error: Select at least one node in the Scene.")
		return
		
	#endregion

	# Replace each selected node with an instance of the selected PackedScene
	for node in selected_nodes:
		var instance: Node3D = resource.instantiate()
		instance.transform = node.transform
		
		var parent = node.get_parent()
		if parent:
			parent.add_child(instance)
			instance.owner = get_editor_interface().get_edited_scene_root()
			instance.name = utilities.get_unique_name(instance.name, parent)
			print("Node has been swapped: " + node.name)
		else:
			print("Error: parent not found for node: " + node.name)
		
		node.queue_free()
