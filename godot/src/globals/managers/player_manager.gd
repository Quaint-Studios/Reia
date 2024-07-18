class_name PlayerManager extends Node
## The PlayerManager class is responsible for managing the player object.
##
## It is responsible for loading the player into the current map and
## keeping track of the player object.

static var instance: PlayerManager

# TODO: Re-enable
# var myPlayer = preload("res://scripts/mob/attackable/player/my_player.tscn")
var player: Player:
	set(value):
		player = value
		if player != null:
			UIManager.instance.enable()
		else:
			UIManager.instance.disable()
	get:
		return player


func _init():
	if instance == null:
		instance = self
	else:
		print("PlayerManager already exists. Deleting this instance.")
		queue_free()
		free()

# Loads the player into the current map.
func load_player():
	print(get_node("/root/Map_Reia"))

	if !get_tree().get_current_scene().is_in_group("map"):
		print("The current scene is not a map. Can't load the player.")

	var map = get_tree().get_current_scene() as MapHandler

	var newPlayer := Player.new() # TODO: Change this to the player scene.

	## Add the player to the map if not running in the editor.
	if !Engine.is_editor_hint()&&player == null:
		print("Setting player")
		player = newPlayer
	map.players.add_child(newPlayer)
