class_name ServerManager extends Node
## Creates a server and handles how many people can join it.
##
## The ServerManager is a part of the Multiplayer namespace.
## It is only ran by authoritative devices and not clients.
## Except when a consumer wants to host their own unofficial
## private game.

#region Signals
signal initialized
signal started
signal stopped
# signal restarted
#endregion

#region Variables
#region Configs
## Default port.
const DEF_PORT = 4337

## Our WebSocketServer instance.
var _server := WebSocketMultiplayerPeer.new()
#endregion

var players := []
#endregion

## Sets up the server.
func _ready():
	setup_signals()
	start_server()

## Sets up the client connected and disconnected signals.
func setup_signals():
	get_tree().set_multiplayer(MultiplayerAPI.create_default_interface(), get_path())
	multiplayer.peer_connected.connect(_on_client_connected)
	multiplayer.peer_disconnected.connect(_on_client_disconnected)

## Cleans up the peer.
func initialize_server():
	multiplayer.multiplayer_peer = null

## Starts the server and updates the peer.
func start_server():
	_server.create_server(DEF_PORT)
	print("Server Started")
	multiplayer.multiplayer_peer = _server

## Stops the server and cleans up.
func stop_server():
	print("Server Stopped")

#
# func restart_server():
#   pass
#

#region Signal Handlers
func _on_client_connected(id: int):
	print("Client (%d) Connected" % id)

func _on_client_disconnected(id: int):
	print("Client (%d) Disconnected" % id)
#endregion
