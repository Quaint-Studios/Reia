@tool
extends EditorPlugin

func execute():
	var selected_paths = get_editor_interface().get_selected_paths()
	
	var json = JSON.new()

	if selected_paths.is_empty():
		print("No file selected.")
		return

	var json_path = selected_paths[0]  # Assuming the first selected file is the JSON.
	if not json_path.ends_with(".json"):
		print("Selected file is not a JSON file.")
		return

	var json_as_text = FileAccess.get_file_as_string(json_path)
	var error = json.parse(json_as_text)
	
	if error == OK:
		var json_data = json.data
		if json_data and "gameObjects" in json_data:
			print("JSON successfully parsed: " + json_path)
			instantiate_scenes_from_json(json_data["gameObjects"])
		else:
			print("Error with json_data: " + json_path)
	
	else:
		print("Failed to parse JSON file: " + json_path)

func instantiate_scenes_from_json(game_objects):
	
	print("Beginning to instantiate prefabs")
	
	var editor = get_editor_interface()
	var current_scene = editor.get_edited_scene_root()

	var last_scene_name = ""
	var last_path = ""
	var path = ""
	var new_path = true
	var scene_resource : PackedScene
	
	for game_object in game_objects:
		var scene_name = game_object["name"] + ".glb"
		
		if (scene_name != last_scene_name):
			
			path = find_scene_resource(scene_name)
			
			if path == "":
				scene_name = game_object["name"] + ".tscn"
				path = find_scene_resource(scene_name)
			
			if path != "":
				scene_resource = load(path) as PackedScene
				
			else:
				print("Error: prefab not found: " + scene_name)
		
		if scene_resource:
			var instance = scene_resource.instantiate()
			setup_instance(instance, current_scene, game_object)
			print("Instantiated: " + instance.name)
		

func find_scene_resource(scene_name: String, start_dir: String = "res://") -> String:
	var dir = DirAccess.open(start_dir)
	if dir:
		dir.include_hidden = false
		dir.include_navigational = false
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			
			var full_path = start_dir.path_join(file_name)
			
			if dir.current_is_dir() and !dir.get_current_dir().begins_with("."):
			
				var result = find_scene_resource(scene_name, full_path)
				if result != "":
					return result
			
			else:
				if file_name == scene_name:
					return full_path
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	else:
		print("Unable to open directory: " + start_dir)
	
	return ""

func setup_instance(instance: Node, current_scene: Node, game_object: Dictionary):
	var transform = Transform3D()

	# Set position
	var pos = Vector3(game_object["position"]["x"], game_object["position"]["y"], game_object["position"]["z"])
	transform.origin = pos

	# Set rotation
	var euler = Vector3(deg_to_rad(game_object["rotation"]["x"]), deg_to_rad(game_object["rotation"]["y"] + 180), deg_to_rad(game_object["rotation"]["z"]))
	var quat = Quaternion.from_euler(euler)
	transform.basis = Basis(quat)

	# Set scale
	var scale = Vector3(game_object["scale"]["x"], game_object["scale"]["y"], game_object["scale"]["z"])
	transform.basis = transform.basis.scaled(scale)

	instance.transform = transform
	current_scene.add_child(instance)
	instance.owner = current_scene

