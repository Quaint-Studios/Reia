class_name MapHandler extends Node

@onready var players : Node = %Players
@export var load_player := true

func _ready():
	GameManager.instance.load_player()

	match MultiplayerManager.instance.status:
		MultiplayerManager.Status.CLIENT:
			var player_name := MultiplayerManager.instance.player_name

			if player_name == null:
				# Should send the player back to the Main Menu to fill out the name.
				return
			MultiplayerManager.instance.handler.register_player(player_name)
