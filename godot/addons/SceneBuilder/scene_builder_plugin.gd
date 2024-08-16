@tool
extends EditorPlugin

var scene_builder_dock : SceneBuilderDock
var scene_builder_commands : SceneBuilderCommands
var scene_builder_input_map : SceneBuilderInputMap

func _enter_tree():
	
	if (ResourceLoader.exists("res://addons/SceneBuilder/scene_builder_dock.gd") and 
		ResourceLoader.exists("res://addons/SceneBuilder/scene_builder_commands.gd") and
		ResourceLoader.exists("res://addons/SceneBuilder/scene_builder_input_map.tres") 
		):
		
		scene_builder_dock = load("res://addons/SceneBuilder/scene_builder_dock.gd").new()
		scene_builder_commands = load("res://addons/SceneBuilder/scene_builder_commands.gd").new()
		scene_builder_input_map = load("res://addons/SceneBuilder/scene_builder_input_map.tres")
	
	# Recursive directories will exist when installing from a submodule
	elif (ResourceLoader.exists("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_dock.gd") and 
		ResourceLoader.exists("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_commands.gd") and
		ResourceLoader.exists("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_input_map.tres")
		):
		
		scene_builder_dock = load("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_dock.gd").new()
		scene_builder_commands = load("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_commands.gd").new()
		scene_builder_input_map = load("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_input_map.tres")
		
	else:
		printerr("scene_builder_dock.gd, scene_builder_commands.gd, or scene_builder_input_map.gd was not found.")
		return
	
	add_child(scene_builder_commands)
	add_child(scene_builder_dock)
	
	scene_builder_commands.update_input_map(scene_builder_input_map)
	scene_builder_dock.update_input_map(scene_builder_input_map)

func _exit_tree():
	scene_builder_commands.queue_free()
	scene_builder_dock.queue_free()

func _handles(object):
	return object is Node3D

func _forward_3d_gui_input(camera : Camera3D, event : InputEvent) -> AfterGUIInput:
	var _return : AfterGUIInput = scene_builder_dock.forward_3d_gui_input(camera, event)
	return _return
