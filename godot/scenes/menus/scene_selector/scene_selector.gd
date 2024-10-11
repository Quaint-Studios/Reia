class_name SceneSelector extends Node
## An organized collection of all possible scenes.
##
## Sends the user to the Main Menu or Jadewater Falls if they're a server,
## and also contains an enum of possible maps.

const SCENE_FOLDER = "res://scenes/"

class CITIES:
	const FOLDER = SCENE_FOLDER + "cities/"

	const WATERBROOK = FOLDER + "waterbrook/waterbrook.tscn"

class REGIONS:
	const FOLDER = SCENE_FOLDER + "regions/"

	const JADEWATER_FALLS = FOLDER + "jadewater_falls/jadewater_falls.tscn"

class DUNGEONS:
	const DUNGEONS_FOLDER = SCENE_FOLDER + "dungeons/"

	class SPIRITS:
		const FOLDER = DUNGEONS_FOLDER + "spirits/"
		const AVAHS_GROVE = FOLDER + "avahs_grove.tscn"

class MENUS:
	const _FOLDER = SCENE_FOLDER + "menus/"

	const MAIN_MENU = _FOLDER + "main_menu/main_menu.tscn"
	const SCENE_SELECTOR = _FOLDER + "scene_selector/scene_selector.tscn"

enum Maps { JADEWATER_FALLS, WATERBROOK }

func _ready() -> void:
	if OS.has_feature("dedicated_server") || DisplayServer.get_name() == "headless" ||  "--server" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred(SceneSelector.REGIONS.JADEWATER_FALLS)
	else:
		get_tree().change_scene_to_file.call_deferred(SceneSelector.MENUS.MAIN_MENU)
