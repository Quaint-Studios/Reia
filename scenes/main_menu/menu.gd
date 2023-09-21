extends Control

@onready var MainRoot = $Margins/Main
@onready var SettingsRoot = $Margins/Settings

@onready var packed_scene_reia = preload(SceneSelector.REIA)

func _ready() -> void:
	Engine.set_max_fps(60)

###
### Main Functions
###
func _on_play_pressed():
	get_tree().change_scene_to_file(SceneSelector.REIA)

func _on_settings_pressed():
	MainRoot.visible = false
	SettingsRoot.visible = true

func _on_exit_pressed():
	get_tree().quit()

###
### Settings
###
func _on_controls_pressed():
	pass # Replace with function body.

func _on_volume_pressed():
	pass # Replace with function body.

func _on_back_pressed():
	MainRoot.visible = true
	SettingsRoot.visible = false
