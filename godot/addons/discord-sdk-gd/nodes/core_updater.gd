## [color=yellow]PLEASE IGNORE![/color] This is a important Node wich gets automatically added as Singleton.
## 
## The DiscordSDKLoader Node automatically gets added as Singleton while installing the addon.
## It has to run in the background to comunicate with Discord.
## You don't need to use it.
##
## @tutorial: https://github.com/vaporvee/discord-sdk-godot/wiki
@tool
class_name core_updater
extends Node

func  _process(_delta):
	if(ProjectSettings.get_setting("DiscordSDK/EditorPresence/enabled") && Engine.is_editor_hint()):
		if(discord_sdk.app_id != 1108142249990176808):
			discord_sdk.app_id = 1108142249990176808
			discord_sdk.details = ProjectSettings.get_setting("application/config/name")
			discord_sdk.state = "Editing: \""+ str(get_tree().edited_scene_root.scene_file_path).replace("res://","") +"\""
			discord_sdk.large_image = "godot"
			discord_sdk.large_image_text = str(Engine.get_version_info().string)
			discord_sdk.start_timestamp = int(Time.get_unix_time_from_system())
			discord_sdk.refresh()
	if(discord_sdk.app_id == 1108142249990176808 || !Engine.is_editor_hint()):
		discord_sdk.coreupdate()
