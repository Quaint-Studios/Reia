@tool
extends EditorPlugin

var path_root = "res://Data/SceneBuilderCollections/"

var editor : EditorInterface
var popup_instance: PopupPanel

# Nodes
var create_items : VBoxContainer

var collection_line_edit : LineEdit

var randomize_vertical_offset_checkbox : CheckButton
var randomize_rotation_checkbox : CheckButton
var randomize_scale_checkbox : CheckButton

var vertical_offset_spin_box_min : SpinBox
var vertical_offset_spin_box_max : SpinBox

var rotx_slider : HSlider
var roty_slider : HSlider
var rotz_slider : HSlider

var scale_spin_box_min : SpinBox
var scale_spin_box_max : SpinBox

var ok_button: Button

var max_diameter : float
var icon_studio : SubViewport

signal done

func execute():
	
	print("Requesting user input...")
	
	editor = get_editor_interface()
	
	popup_instance = PopupPanel.new()
	add_child(popup_instance)
	popup_instance.popup_centered(Vector2(500, 300))
	
	create_items = load("res://addons/SceneBuilder/scene_builder_create_items.tscn").instantiate()
	popup_instance.add_child(create_items)
	
	collection_line_edit = create_items.get_node("Collection/LineEdit")
	randomize_vertical_offset_checkbox = create_items.get_node("Boolean/VerticalOffset")
	randomize_rotation_checkbox = create_items.get_node("Boolean/Rotation")
	randomize_scale_checkbox = create_items.get_node("Boolean/Scale")
	vertical_offset_spin_box_min = create_items.get_node("VerticalOffset/min")
	vertical_offset_spin_box_max = create_items.get_node("VerticalOffset/max")
	rotx_slider = create_items.get_node("Rotation/x")
	roty_slider = create_items.get_node("Rotation/y")
	rotz_slider = create_items.get_node("Rotation/z")
	scale_spin_box_min = create_items.get_node("Scale/min")
	scale_spin_box_max = create_items.get_node("Scale/max")
	ok_button = create_items.get_node("Okay")
	
	ok_button.pressed.connect(_on_ok_pressed)

func _on_ok_pressed():
	
	print("User input has been set")
	
	var path_to_icon_studio : String = "res://addons/SceneBuilder/icon_studio.tscn"
	if FileAccess.file_exists(path_to_icon_studio):
		
		editor.open_scene_from_path(path_to_icon_studio)
		
		icon_studio = editor.get_edited_scene_root() as SubViewport
		if icon_studio == null:
			print("Failed to load icon studio")
			return
		
		var selected_paths = editor.get_selected_paths()
		print("Selected paths: " + str(selected_paths.size()))
		for path in selected_paths:
			await _create_resource(path)
		
	else:
		print("Path to icon studio not found")
		return 
	
	popup_instance.queue_free()
	emit_signal("done")

func _create_resource(path: String):
	
	var resource : SceneBuilderItem = load("res://addons/SceneBuilder/scene_builder_item.gd").new()
	
	if ResourceLoader.exists(path) and load(path) is PackedScene:
		
		#region Populate resource
		
		resource.scene_path = path
		resource.item_name = path.get_file().get_basename()
		resource.collection_name = collection_line_edit.text
		
		resource.use_random_vertical_offset = randomize_vertical_offset_checkbox.button_pressed
		resource.use_random_rotation = randomize_rotation_checkbox.button_pressed
		resource.use_random_scale = randomize_scale_checkbox.button_pressed
		
		resource.random_offset_y_min = vertical_offset_spin_box_min.value
		resource.random_offset_y_max = vertical_offset_spin_box_max.value
		
		resource.random_rot_x = rotx_slider.value
		resource.random_rot_y = roty_slider.value
		resource.random_rot_z = rotz_slider.value
		
		resource.random_scale_min = scale_spin_box_min.value
		resource.random_scale_min = scale_spin_box_min.value
		
		#endregion
		
		#region Create directories
		
		var path_to_collection_folder = path_root + resource.collection_name
		var path_to_item_folder = path_to_collection_folder + "/Item"
		var path_to_thumbnail_folder = path_to_collection_folder + "/Thumbnail"
		
		print("coll: " + path_to_collection_folder)
		create_directory_if_not_exists(path_to_collection_folder)
		print("item")
		create_directory_if_not_exists(path_to_item_folder)
		print("thumbnail")
		create_directory_if_not_exists(path_to_thumbnail_folder)

		#endregion

		#region Create icon
		
		# Validate
		if not resource.scene_path.ends_with(".glb") and not resource.scene_path.ends_with(".tscn"):
			print("Invalid scene file. Must end with .glb or .tscn")
			return
		var packed_scene = load(resource.scene_path) as PackedScene
		if packed_scene == null:
			print("Failed to load the item scene.")
			return

		var object_name = resource.scene_path.get_file().get_basename()
		
		# Add packed_scene to studio scene
		var subject : Node3D = packed_scene.instantiate()
		icon_studio.add_child(subject)
		subject.owner = icon_studio
		
		var studio_camera : Camera3D = icon_studio.get_node("CameraRoot/Pitch/Camera3D") as Camera3D
		
		max_diameter = 0.0
		search_for_mesh_instance_3d(subject)
		print("max_diameter: ", max_diameter)
		studio_camera.position = Vector3(0, 0, max_diameter)
		
		await get_tree().process_frame
		await get_tree().process_frame
		
		var viewport_tex : Texture = icon_studio.get_texture()
		var img : Image = viewport_tex.get_image()
		var tex : Texture = ImageTexture.create_from_image(img)
		
		var save_path = path_root + "%s/Thumbnail/%s.png" % [resource.collection_name, object_name]
		print("Saving icon to: ", save_path)
		img.save_png(save_path)
		
		await get_tree().process_frame
		
		subject.queue_free()
	
		#endregion
		
		save_path = path_to_item_folder + "/%s.tres" % resource.item_name
		ResourceSaver.save(resource, save_path)
		print("Resource saved: " + save_path)

func create_directory_if_not_exists(path_to_directory: String) -> void:
	var dir = DirAccess.open(path_to_directory)
	if not dir:
		print("Creating directory: " + path_to_directory)
		DirAccess.make_dir_recursive_absolute(path_to_directory)

func search_for_mesh_instance_3d(node : Node):
	
	if node is MeshInstance3D:
		var aabb = node.get_mesh().get_aabb()
		var diameter = aabb.size.length()
		print("node name w/ diameter: ", node.name, ", ", diameter)
		max_diameter = max(max_diameter, diameter)
	for child in node.get_children():
		search_for_mesh_instance_3d(child)



'''var img_tmp_icon : Image
var tex_tmp_icon : Texture
icon_tmp = load("res://addons/SceneBuilder/icon_tmp.png") as Image
var img_icon : Image = icon_tmp
var tex_icon : Texture = ImageTexture.create_from_image(img_icon)'''
