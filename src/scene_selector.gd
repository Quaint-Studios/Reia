class_name SceneSelector extends Node

const SCENE_FOLDER = "res://scenes/"
const MAIN_MENU = SCENE_FOLDER + "/main_menu/main_menu.tscn"
const REIA = SCENE_FOLDER + "reia/reia.tscn"

enum Maps { REIA }

func _ready():
	if OS.has_feature("dedicated_server") || DisplayServer.get_name() == "headless" ||  "--server" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file(SceneSelector.REIA)
	else:
		get_tree().change_scene_to_file(SceneSelector.MAIN_MENU)
