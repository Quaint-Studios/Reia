@tool
extends EditorPlugin

var editor : EditorInterface
var space : PhysicsDirectSpaceState3D 
var world3d : World3D
var viewport : Viewport

func execute():
	
	editor = get_editor_interface()
	viewport = editor.get_editor_viewport_3d()
	var scene_root = editor.get_edited_scene_root()
	world3d = viewport.find_world_3d()
	space = world3d.direct_space_state
	var mouse_pos = viewport.get_mouse_position()
	var camera = viewport.get_camera_3d()	
	var selected_paths = editor.get_selected_paths()
	var editor_selection = editor.get_selection()
	var selected_nodes = editor_selection.get_selected_nodes()
	
	if (camera == null):
		print("null camera")
		return
	else:
		print("mouse pos: " + str(mouse_pos))
	
	if selected_paths.size() == 0:
		print("One or more paths must be selected in FileSystem")
		return
	
	var packed_scenes = []
	for path in selected_paths:
		if ResourceLoader.exists(path) and load(path) is PackedScene:
			packed_scenes.append(load(path))
	
	if packed_scenes.size() != selected_paths.size():
		print("All selected paths must be of type PackedScene")
		return
	
	var random_scene = packed_scenes[randi() % packed_scenes.size()]
	
	var parent_node = scene_root
	if selected_nodes.size() == 1:
		parent_node = selected_nodes[0]
	
	if random_scene:
		var instance = random_scene.instantiate()
		var transform = Transform3D.IDENTITY
		
		var origin = camera.project_ray_origin(mouse_pos)
		var end = origin + camera.project_ray_normal(mouse_pos) * 1000
		var query = PhysicsRayQueryParameters3D.new()
		query.from = origin
		query.to = end
		var result : Dictionary = space.intersect_ray(query)
				
		if result and result.collider:
			transform.origin = result.position
		else:
			print("No hit")
			transform.origin = Vector3.ZERO
		
		# Apply random rotation and scale
		#var rand_rot = Quaternion(Vector3.UP, deg_to_rad(randf() * 360))
		#var rand_scale = Vector3(randf_range(0.9, 1.1), randf_range(0.9, 1.1), randf_range(0.9, 1.1))
		#transform = Transform3D(rand_rot, transform.origin).scaled(rand_scale)
		
		parent_node.add_child(instance)
		instance.owner = scene_root
		instance.global_transform = transform
		
		editor_selection.clear()
		editor_selection.add_node(instance)
		
		print("Instantiated: " + instance.name + " at " + str(instance.global_transform.origin))

