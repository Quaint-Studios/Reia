extends Control

@export var menu_music: AudioStream

@onready var packed_scene_reia = preload(SceneSelector.REIA)

func _ready():
	_prepare_sound()
	pass

func _prepare_sound():
	SoundManager.set_sound_volume(0.5)
	SoundManager.set_music_volume(0.5)

	SoundManager.play_music(menu_music, 1.0)

	update_volumes()

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


func _on_master_volume_changed(value: float):
	SoundManager.set_master_volume(value)
	update_volumes()
func _on_music_volume_changed(value: float):
	SoundManager.set_music_volume(value)
	update_volumes()
func _on_sfx_volume_changed(value: float):
	SoundManager.set_sound_volume(value)
	update_volumes()
func _on_ui_volume_changed(value: float):
	SoundManager.set_ui_sound_volume(value)
	update_volumes()
func _on_dialogue_volume_changed(value: float):
	SoundManager.set_dialogue_volume(value)
	update_volumes()

func volume_to_perc(vol: float) -> String:
	var perc: int = clamp(int(vol * 100), 0, 100)
	return str(perc) + "%"

func update_volumes():
	%MasterVolume.value = SoundManager.get_master_volume()
	%MasterVolumeLabel.text = volume_to_perc(SoundManager.get_master_volume())
	%MusicVolume.value = SoundManager.get_music_volume()
	%MusicVolumeLabel.text = volume_to_perc(SoundManager.get_music_volume())
	%SFXVolume.value = SoundManager.get_sound_volume()
	%SFXVolumeLabel.text = volume_to_perc(SoundManager.get_sound_volume())
	%UIVolume.value = SoundManager.get_ui_sound_volume()
	%UIVolumeLabel.text = volume_to_perc(SoundManager.get_ui_sound_volume())
	%DialogueVolume.value = SoundManager.get_dialogue_volume()
	%DialogueVolumeLabel.text = volume_to_perc(SoundManager.get_dialogue_volume())

