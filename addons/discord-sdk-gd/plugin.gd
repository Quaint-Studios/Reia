@tool
extends EditorPlugin

const DiscordSDKDebug = preload("res://addons/discord-sdk-gd/nodes/debug.gd")
const DiscordSDKDebug_icon = preload("res://addons/discord-sdk-gd/Debug.svg")
var loaded_DiscordSDKDebug = DiscordSDKDebug.new()
var restart_window: Control = preload("res://addons/discord-sdk-gd/restart_window.tscn").instantiate()


func _enter_tree() -> void:
	add_custom_type("DiscordSDKDebug","Node",DiscordSDKDebug,DiscordSDKDebug_icon)
	add_autoload_singleton("DiscordSDKLoader", "res://addons/discord-sdk-gd/nodes/core_updater.gd")
	ProjectSettings.set_setting("DiscordSDK/EditorPresence/enabled",false)
	ProjectSettings.set_as_basic("DiscordSDK/EditorPresence/enabled",true)
	ProjectSettings.set_initial_value("DiscordSDK/EditorPresence/enabled",false)
	ProjectSettings.set_restart_if_changed("DiscordSDK/EditorPresence/enabled",true)

func _enable_plugin() -> void:
	if FileAccess.file_exists(ProjectSettings.globalize_path("res://") + "addons/discord-sdk-gd/bin/.gdignore"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://") + "addons/discord-sdk-gd/bin/.gdignore")
	if FileAccess.file_exists(ProjectSettings.globalize_path("res://") + "addons/discord-sdk-gd/nodes/.gdignore"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://") + "addons/discord-sdk-gd/nodes/.gdignore")
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR,restart_window)
	restart_window.get_child(0).connect("canceled",save_restart)
	restart_window.get_child(0).connect("confirmed",restart)

func _disable_plugin() -> void:
	FileAccess.open("res://addons/discord-sdk-gd/bin/.gdignore",FileAccess.WRITE)
	FileAccess.open("res://addons/discord-sdk-gd/nodes/.gdignore",FileAccess.WRITE)
	push_warning("DiscordSDK Addon got disabled. PLEASE RESTART THE EDITOR!")
	remove_autoload_singleton("DiscordSDKLoader")
	remove_custom_type("DiscordSDKDebug")
	ProjectSettings.clear("DiscordSDK/EditorPresence/enabled")

func save_restart() -> void:
	get_editor_interface().restart_editor(true)

func restart() -> void:
	get_editor_interface().restart_editor(false)
