@tool
extends EditorPlugin

var scene_builder_dock
var scene_builder_commands

func _enter_tree():
	
	if (FileAccess.file_exists("res://addons/SceneBuilder/scene_builder_dock.gd") and 
		FileAccess.file_exists("res://addons/SceneBuilder/scene_builder_commands.gd")):
		
		scene_builder_dock = load("res://addons/SceneBuilder/scene_builder_dock.gd").new()
		scene_builder_commands = load("res://addons/SceneBuilder/scene_builder_commands.gd").new()
	
	elif (FileAccess.file_exists("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_dock.gd") and 
		  FileAccess.file_exists("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_commands.gd")):
		
		# Recursive directories will exist when installing from a submodule
		
		scene_builder_dock = load("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_dock.gd").new()
		scene_builder_commands = load("res://addons/SceneBuilder/addons/SceneBuilder/scene_builder_commands.gd").new()
	
	else:
		printerr("scene_builder_dock.gd or scene_builder_commands.gd was not found.")
		return
	
	add_child(scene_builder_commands)
	add_child(scene_builder_dock)

func _exit_tree():
	scene_builder_commands.queue_free()
	scene_builder_dock.queue_free()

func _handles(object):
	return object is Node3D

func _forward_3d_gui_input(camera : Camera3D, event : InputEvent) -> AfterGUIInput:
	var _return : AfterGUIInput = scene_builder_dock.forward_3d_gui_input(camera, event)
	return _return
