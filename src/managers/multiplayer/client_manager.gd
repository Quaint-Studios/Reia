class_name ClientManager extends Node
## Connects to a server.`
##
## The ClientManager is a part of the Multiplayer namespace.
## It runs on all client devices and handles all client-side
## functionality.

#region Signals
# ...
#endregion

#region Variables
#region Configs
## Host IP. Defaults to 127.0.0.1.
var host = "127.0.0.1"

## Default port.
const DEF_PORT = 4337

## Our WebSocketClient instance.
var _client := WebSocketMultiplayerPeer.new()
#endregion

var players := []
#endregion

## Sets up the server.
func _ready():
	setup_signals()
	start_client()

## Sets up the client connected and disconnected signals.
func setup_signals():
	multiplayer.peer_connected.connect(_on_client_connected)
	multiplayer.peer_disconnected.connect(_on_client_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Starts the server and updates the peer.
func start_client():
	multiplayer.multiplayer_peer = null
	_client.create_client("ws://" + host + ":" + str(DEF_PORT))
	multiplayer.multiplayer_peer = _client
	print("Server Started")

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

func _on_server_disconnected():
	print("Server Connection Lost")
#endregion
