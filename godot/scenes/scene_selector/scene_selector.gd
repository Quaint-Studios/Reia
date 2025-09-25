class_name SceneSelector extends Node
## An organized collection of all possible scenes.
##
## Sends the user to the Main Menu or Jadewater Falls if they're a server,
## and also contains an enum of possible maps.

const SCENE_FOLDER = "res://scenes/"

class CITIES:
	const FOLDER = SCENE_FOLDER + "cities/"


class REGIONS:
	const FOLDER = SCENE_FOLDER + "regions/"

	const JADEWATER_FALLS = FOLDER + "jadewater_falls/jadewater_falls.tscn"
	const WATERBROOK_CITY = FOLDER + "waterbrook_city/waterbrook_city.tscn"

class DUNGEONS:
	const DUNGEONS_FOLDER = SCENE_FOLDER + "dungeons/"

	class SPIRITS:
		const FOLDER = DUNGEONS_FOLDER + "spirits/"
		const AVAHS_GROVE = FOLDER + "avahs_grove.tscn"

class MAIN:
	const _FOLDER = SCENE_FOLDER

	const TITLE_SCREEN = _FOLDER + "title_screen/title_screen.tscn"
	const SCENE_SELECTOR = _FOLDER + "scene_selector/scene_selector.tscn"

enum Maps {JADEWATER_FALLS, WATERBROOK_CITY}

func _ready() -> void:
	if OS.has_feature("dedicated_server") || DisplayServer.get_name() == "headless" || "--server" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred(SceneSelector.REGIONS.JADEWATER_FALLS)
	else:
		get_tree().change_scene_to_file.call_deferred(SceneSelector.MAIN.TITLE_SCREEN)

static func change_map(tree: SceneTree, to: Maps) -> void:
	match to:
		Maps.JADEWATER_FALLS:
			tree.change_scene_to_file.call_deferred(SceneSelector.REGIONS.JADEWATER_FALLS)
		Maps.WATERBROOK_CITY:
			tree.change_scene_to_file.call_deferred(SceneSelector.REGIONS.WATERBROOK_CITY)
		_:
			push_error("Invalid map selection.")
