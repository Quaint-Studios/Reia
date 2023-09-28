extends Control

@export var menu_music: AudioStream

@onready var packed_scene_reia = preload(SceneSelector.REIA)

func _ready():
	_prepare_sound()
	pass

func _prepare_sound():
	SoundManager.set_sound_volume(0.5)
	#%SoundVolume.text = "50%"
	SoundManager.set_music_volume(0.5)
	#%MusicVolume.text = "50%"

	SoundManager.play_music(menu_music, 1.0)

###
### Main Functions
###
func _on_play_pressed():
	GameManager.current_ui = GameManager.UI_TYPES.PLAY
	get_tree().change_scene_to_file(SceneSelector.REIA)

func _on_settings_pressed():
	%Main.visible = false
	%Settings.visible = true

func _on_exit_pressed():
	get_tree().quit()

###
### Settings
###
func _on_controls_pressed():
	disable_all_roots()
	%Controls.visible = true

func _on_volume_pressed():
	disable_all_roots()
	%Volume.visible = true

func _on_back_pressed():
	if %Settings.visible:
		disable_all_roots()
		%Main.visible = true

	if %Controls.visible || %Volume.visible:
		disable_all_roots()
		%Settings.visible = true

func disable_all_roots():
	%Main.visible = false
	%Settings.visible = false
	%Controls.visible = false
	%Volume.visible = false


func _on_master_volume_changed(value):
	pass # Replace with function body.


func _on_music_volume_changed(value):
	SoundManager.set_music_volume(linear_to_db(value))
	pass # Replace with function body.

func _on_sfx_volume_changed(value):
	SoundManager.set_sound_volume(linear_to_db(value))
	pass # Replace with function body.

func _on_ui_volume_changed() -> void:
	pass # Replace with function body.

func _on_dialogue_volume_changed(value):
	pass # Replace with function body.
