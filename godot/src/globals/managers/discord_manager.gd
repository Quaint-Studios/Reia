extends Node
## Discord SDK
##
## This script is used to set the Rich Presence of the Discord SDK.

func _ready() -> void:
	if OS.has_feature("wasm32") || OS.has_feature("wasm") || OS.has_feature("mobile"):
		return

	# DiscordRPC.app_id = 688581385639952418 # Application ID
	# DiscordRPC.details = "Roaming the world..."
	# DiscordRPC.state = "Playing Solo"

	# DiscordRPC.large_image = "logo_a_1024" # Image key from "Art Assets"
	# DiscordRPC.large_image_text = ""
	# DiscordRPC.small_image = "" # Image key from "Art Assets"
	# DiscordRPC.small_image_text = ""

	# DiscordRPC.current_party_size = 1
	# DiscordRPC.max_party_size = 5

	# DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# # DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00 remaining"

	# DiscordRPC.refresh() # Always refresh after changing the values!
