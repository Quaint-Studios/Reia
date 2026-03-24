extends Node

const SERVER_SCENE = preload("res://server/server_main.tscn")
const CLIENT_SCENE = preload("res://client/client_main.tscn")

func _ready() -> void:
	if OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		_boot_server()
	else:
		_boot_client()

func _boot_server() -> void:
	print("[BOOT] Initializing Dedicated Server...")
	var server_instance := SERVER_SCENE.instantiate() as ServerMain
	get_tree().root.add_child.call_deferred(server_instance)
	queue_free()

func _boot_client() -> void:
	print("[BOOT] Initializing Client Presentation...")
	var client_instance := CLIENT_SCENE.instantiate() as ClientMain
	get_tree().root.add_child.call_deferred(client_instance)
	queue_free()
