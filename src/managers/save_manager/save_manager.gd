@tool class_name SaveManager extends Node

@export var save_my_player := false:
	set(value):
		print("saving player (1)...")
		SaveManager.save_player(GameManager.player)
		print("player saved.")
		save_my_player = false

const save_dir = "user://saves/"

static func get_player_path(player_name: String) -> String:
	var save_file := "%s.save" % player_name
	return "%scharacters/%s" % [save_dir, save_file]

static func save_player(player: Player):
	var save_path := get_player_path(player.name)

	var data := player.toJSON()
	
	var json_string = JSON.stringify(data)
	
	print(json_string)

static func load_player(player_name: String):
	var save_path := get_player_path(player_name)
	
	if ResourceLoader.has_cached(save_path):
		return ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_REUSE)
