extends Node
## Discord SDK
##
## This script is used to set the Rich Presence of the Discord SDK.

func _ready():
	discord_sdk.app_id = 688581385639952418 # Application ID
	discord_sdk.details = "Roaming the world..."
	discord_sdk.state = "Playing Solo"

	discord_sdk.large_image = "logo_a_1024" # Image key from "Art Assets"
	discord_sdk.large_image_text = ""
	discord_sdk.small_image = "" # Image key from "Art Assets"
	discord_sdk.small_image_text = ""

	discord_sdk.current_party_size = 1
	discord_sdk.max_party_size = 5

	discord_sdk.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# discord_sdk.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00 remaining"

	discord_sdk.refresh() # Always refresh after changing the values!
