extends Node
## AUTOLOAD: UserPreferences
## Handles saving and loading local client settings (Username, Audio Levels, Keybinds).

const PREFS_PATH = "user://client_prefs.cfg"

var _config := ConfigFile.new()

func _ready() -> void:
	var err := _config.load(PREFS_PATH)
	if err != OK:
		print("Failed to load user preferences: ", err)

func save_username(username: String) -> void:
	_config.set_value("Auth", "username", username)
	var err := _config.save(PREFS_PATH)
	if err != OK:
		print("Failed to save user preferences: ", err)

func get_username() -> String:
	return _config.get_value("Auth", "username", "Adventurer")
