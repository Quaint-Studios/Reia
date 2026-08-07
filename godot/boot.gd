extends Node

const SERVER_SCENE = preload("res://server/server_main.tscn")
const CLIENT_SCENE = preload("res://client/client_main.tscn")

func _ready() -> void:
	var cmd_args := OS.get_cmdline_args()
	var is_server := not cmd_args.has("--client") and (
		cmd_args.has("--server")
		or OS.has_feature("dedicated_server")
		or DisplayServer.get_name() == "headless"
	)

	if is_server:
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
