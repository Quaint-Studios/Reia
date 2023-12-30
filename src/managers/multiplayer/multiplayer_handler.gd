class_name MultiplayerHandler extends Node
## Handles Multiplayer RPC calls.
##
## This script handles most of the multiplayer interactions but
## not all of them. It's also a part of the Multiplayer namespace.

#region Signals
signal player_connected
#endregion

#region Variables
var _players = {}
#endregion

#region Core Funcs
class TestPlayer:
	var name: String

	func _init(_name: String):
		name = _name
#endregion


#region Server only
## When a player connects, tell all of the other players
## their information.
@rpc("authority", "reliable")
func register_player(player_name: String):
	var player_id = multiplayer.get_remote_sender_id()
	_players[player_id] = TestPlayer.new(player_name)
	player_connected.emit()
#endregion