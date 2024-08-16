class_name MapHandler extends Node

@onready var players : Node = %Players
@export var load_player := true

func _ready() -> void:
	match MultiplayerManager.instance.status:
		MultiplayerManager.Status.CLIENT:
			var player_name := MultiplayerManager.instance.player_name

			if player_name == null:
				# Should send the player back to the Main Menu to fill out the name.
				return

			MultiplayerManager.instance.myClient.start_client()
			return

	PlayerManager.instance.load_player()
