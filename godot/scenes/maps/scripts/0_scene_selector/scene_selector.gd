## Used to create
class_name SceneSelector extends Node

const SCENE_FOLDER = "res://scenes/"
const MAIN_MENU = SCENE_FOLDER + "maps/1_main_menu.tscn"
const JADEWATER_FALLS = SCENE_FOLDER + "maps/2_jadewater_falls.tscn"
const WATERBROOK = SCENE_FOLDER + "maps/3_waterbrook.tscn"

enum Maps { JADEWATER_FALLS, WATERBROOK }

func _ready():
	if OS.has_feature("dedicated_server") || DisplayServer.get_name() == "headless" ||  "--server" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred(SceneSelector.JADEWATER_FALLS)
	else:
		get_tree().change_scene_to_file.call_deferred(SceneSelector.MAIN_MENU)
