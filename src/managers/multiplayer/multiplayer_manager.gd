class_name MultiplayerManager extends Node

static var myClient : ClientManager
static var myServer : ServerManager

func _ready():
	if OS.has_feature("dedicated_server") || DisplayServer.get_name() == "headless" ||  "--server" in OS.get_cmdline_user_args():
		myServer = ServerManager.new()
		myServer.name = "ServerManager"
		myServer.autostart = true
		add_child(myServer)
	else:
		myClient = ClientManager.new()
		myClient.name = "ClientManager"
		add_child(myClient)
