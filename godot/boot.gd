extends Node

const SERVER_SCENE = preload("res://server/server_main.tscn")
const CLIENT_SCENE = preload("res://client/client_main.tscn")

func _ready() -> void:
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--server"):
		_boot_server()
	else:
		_boot_client()

func _boot_server() -> void:
	print("[BOOT] Dedicated Server flag detected.")
	var server_instance := SERVER_SCENE.instantiate() as ServerMain
	get_tree().root.add_child.call_deferred(server_instance)
	queue_free()

func _boot_client() -> void:
	print("[BOOT] Client environment detected.")
	SceneManager.transition_to_screen(Scenes.Menus.TITLE_SCREEN)
	queue_free()
