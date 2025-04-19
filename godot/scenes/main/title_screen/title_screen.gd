extends Node

@export var menu_music: AudioStream

@onready var packed_scene_reia := preload(SceneSelector.REGIONS.JADEWATER_FALLS)

func _ready() -> void:
	_prepare_screens()
	_prepare_sound()

func _prepare_screens() -> void:
	hide_all_screens()
	_on_screen_change("title")

func _prepare_sound() -> void:
	SoundManager.set_sound_volume(0.4)
	SoundManager.set_music_volume(0.4)

	# Audio Stream Player
	var _asp := SoundManager.play_music(menu_music, 1.0)

	#update_volumes()

func hide_all_screens() -> void:
	(%Title as Control).hide()
	(%Play as Control).hide()
	(%Settings as Control).hide()
	(%Credits as Control).hide()

## Handles where to go when a nav button is pressed.
##
## @param to: The screen to go back to.
func _on_screen_change(to: String) -> void:
	match to:
		"title":
			hide_all_screens()
			(%Title as Control).show()
		"play":
			hide_all_screens()
			(%Play as Control).show()
		"settings":
			hide_all_screens()
			(%Settings as Control).show()
		"credits":
			hide_all_screens()
			(%Credits as Control).show()
		"quit":
			hide_all_screens()
			(%Quit as Control).show()

# old code below

# func play_game() -> void:
# 	GameManager.state = GameManager.GAME_STATES.PLAY
# 	var err := get_tree().change_scene_to_packed(packed_scene_reia)

# 	assert(err == Error.OK, "There was a problem loading the scene.")

# ###
# ### Main Functions
# ###
# func _on_play_pressed() -> void:
# 	disable_all_roots()
# 	%PlayChoice.show()
# 	%Blur.show()


# func _on_settings_pressed():
# 	%Main.visible = false
# 	%Settings.visible = true

# func _on_exit_pressed():
# 	get_tree().quit()

# ###
# ### Settings
# ###
# func _on_controls_pressed():
# 	disable_all_roots()
# 	%Controls.visible = true

# func _on_volume_pressed():
# 	disable_all_roots()
# 	%Volume.visible = true

# func _on_back_pressed():
# 	if %Settings.visible:
# 		disable_all_roots()
# 		%Main.visible = true

# 	if %Controls.visible || %Volume.visible:
# 		disable_all_roots()
# 		%Settings.visible = true

# func disable_all_roots():
# 	%Main.visible = false
# 	%Settings.visible = false
# 	%Controls.visible = false
# 	%Volume.visible = false
# 	%PlayChoice.visible = false
# 	%OnlineForm.visible = false
# 	%Blur.visible = false

# #
# #func _on_master_volume_changed(value: float):
# 	#SoundManager.set_master_volume(value)
# 	#update_volumes()
# #func _on_music_volume_changed(value: float):
# 	#SoundManager.set_music_volume(value)
# 	#update_volumes()
# #func _on_sfx_volume_changed(value: float):
# 	#SoundManager.set_sound_volume(value)
# 	#update_volumes()
# #func _on_ui_volume_changed(value: float):
# 	#SoundManager.set_ui_sound_volume(value)
# 	#update_volumes()
# #func _on_dialogue_volume_changed(value: float):
# 	#SoundManager.set_dialogue_volume(value)
# 	#update_volumes()

# func volume_to_perc(vol: float) -> String:
# 	var perc: int = clamp(int(vol * 100), 0, 100)
# 	return str(perc) + "%"

# #func update_volumes():
# 	#%MasterVolume.value = SoundManager.get_master_volume()
# 	#%MasterVolumeLabel.text = volume_to_perc(SoundManager.get_master_volume())
# 	#%MusicVolume.value = SoundManager.get_music_volume()
# 	#%MusicVolumeLabel.text = volume_to_perc(SoundManager.get_music_volume())
# 	#%SFXVolume.value = SoundManager.get_sound_volume()
# 	#%SFXVolumeLabel.text = volume_to_perc(SoundManager.get_sound_volume())
# 	#%UIVolume.value = SoundManager.get_ui_sound_volume()
# 	#%UIVolumeLabel.text = volume_to_perc(SoundManager.get_ui_sound_volume())
# 	#%DialogueVolume.value = SoundManager.get_dialogue_volume()
# 	#%DialogueVolumeLabel.text = volume_to_perc(SoundManager.get_dialogue_volume())


# #region Play Choice
# func _on_online_button_pressed():
# 	disable_all_roots()
# 	%OnlineForm.show()
# 	%Blur.show()
# 	(%PlayerName as TextEdit).grab_focus()

# func _on_offline_button_pressed():
# 	MultiplayerManager.instance.status = MultiplayerManager.Status.OFFLINE
# 	play_game()

# func _on_play_choice_back_button_pressed():
# 	disable_all_roots()
# 	%Main.show()
# #endregion

# #region Online Form
# func _on_player_name_text_changed():
# 	var final_text := ""
# 	var player_name := %PlayerName as TextEdit

# 	var regex = RegEx.new()
# 	regex.compile("[a-zA-Z0-9 ]{0,20}")

# 	var regex_match = regex.search_all(player_name.text)
# 	if regex_match:
# 		final_text = regex_match[0].get_string()

# 	player_name.text = final_text
# 	player_name.set_caret_column(player_name.text.length())
# 	MultiplayerManager.instance.player_name = player_name.text

# 	var cnb = (%ConfirmNameButton as Button)

# 	if player_name.text.length() <= 0:
# 		cnb.disabled = true
# 	else:
# 		cnb.disabled = false

# func _on_confirm_name_button_pressed():
# 	var player_name := (%PlayerName as TextEdit).text
# 	if player_name.length() > 0 && player_name.length() <= 20:
# 		MultiplayerManager.instance.player_name = player_name
# 		MultiplayerManager.instance.status = MultiplayerManager.Status.CLIENT
# 		play_game()

# func _on_online_form_back_button_pressed():
# 	disable_all_roots()
# 	%PlayChoice.show()
# 	%Blur.show()
# #endregion
