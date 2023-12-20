class_name ServerManager extends Node
## Creates a server and handles how many people can join it.
##
## The ServerManager is a part of the Multiplayer namespace.
## It is only ran by authoritative devices and not clients.
## Except when a consumer wants to host their own unofficial
## private game.

signal initialized
signal started
signal stopped
# signal restarted


#region Variables
var players := []
#endregion

## Sets up the server.
func _ready():
  initialize_server()
  start_server()

## Changes the multiplayer of this node to a new instance.
func initialize_server():
  pass

## Starts the server and cleans up.
func start_server():
  pass

## Stops the server and cleans up.
func stop_server():
  pass

#
# func restart_server():
#   pass
#
