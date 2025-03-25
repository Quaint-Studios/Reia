@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("SoundManager", get_plugin_path() + "/sound_manager.gd")


func _exit_tree():
	remove_autoload_singleton("SoundManager")


func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()
