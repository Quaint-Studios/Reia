class_name MultiplayerManager extends Node

var myClient : ClientManager
var myServer : ServerManager
var handler : MultiplayerHandler
var player_name : String

enum Status { UNSET, CLIENT, SERVER, BOTH, OFFLINE }
var status = Status.UNSET

static var instance : MultiplayerManager

func _init():
	if instance == null:
		instance = self

func _ready():
	setup_handlers()

	if OS.has_feature("dedicated_server") || DisplayServer.get_name() == "headless" ||  "--server" in OS.get_cmdline_user_args():
		myServer = ServerManager.new()
		myServer.name = "ServerManager"
		myServer.autostart = true
		add_child(myServer)
	else:
		myClient = ClientManager.new()
		myClient.name = "ClientManager"
		add_child(myClient)

func setup_handlers():
	# for in [MultiplayerHandler, ...]
	var node = MultiplayerHandler.new()
	node.name = "MultiplayerHandler"
	add_child(node)
