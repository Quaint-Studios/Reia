extends Node
## This should be scrapped and instead placed in the Player script itself.
## More designing is required.

# TODO: Re-enable
# var myPlayer = preload("res://scripts/mob/attackable/player/my_player.tscn")
# var player: Player

func load_player():
	print(get_node("/root/Map_Reia"))

	if !get_tree().get_current_scene().is_in_group("map"):
		print("The current scene is not a map. Can't load the player.")

	var map = get_tree().get_current_scene() as MapHandler

	# var newPlayer := myPlayer.instantiate() as Player

	if !Engine.is_editor_hint()&&GameManager.instance.player == null:
		print("Setting player")
		## GameManager.instance.player = newPlayer
	## map.players.add_child(newPlayer)