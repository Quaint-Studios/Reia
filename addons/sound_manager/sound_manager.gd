extends Node


const SoundEffectsPlayer = preload("res://addons/sound_manager/sound_effects.gd")
const MusicPlayer = preload("res://addons/sound_manager/music.gd")

var sound_effects: SoundEffectsPlayer = SoundEffectsPlayer.new(["Sounds", "SFX"], 8)
var ui_sound_effects: SoundEffectsPlayer = SoundEffectsPlayer.new(["UI", "Interface", "Sounds", "SFX"], 8)
var music: MusicPlayer = MusicPlayer.new(["Music"], 2)

var sound_process_mode: ProcessMode:
	set(value):
		sound_effects.process_mode = value
	get:
		return sound_effects.process_mode

var ui_sound_process_mode: ProcessMode:
	set(value):
		ui_sound_effects.process_mode = value
	get:
		return ui_sound_effects.process_mode

var music_process_mode: ProcessMode:
	set(value):
		music.process_mode = value
	get:
		return music.process_mode

func _init() -> void:
	add_child(sound_effects)
	add_child(ui_sound_effects)
	add_child(music)
	add_child(dialogue)

	self.sound_process_mode = PROCESS_MODE_PAUSABLE
	self.ui_sound_process_mode = PROCESS_MODE_ALWAYS
	self.music_process_mode = PROCESS_MODE_ALWAYS
	self.dialogue_process_mode = PROCESS_MODE_ALWAYS


func get_sound_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(sound_effects.bus)))


func get_ui_sound_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(ui_sound_effects.bus)))


func set_sound_volume(volume_between_0_and_1) -> void:
	_show_shared_bus_warning()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(sound_effects.bus), linear_to_db(volume_between_0_and_1))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(ui_sound_effects.bus), linear_to_db(volume_between_0_and_1))


func play_sound(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	return sound_effects.play(resource, override_bus)


func play_ui_sound(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	return ui_sound_effects.play(resource, override_bus)


func set_default_sound_bus(bus: String) -> void:
	sound_effects.bus = bus


func set_default_ui_sound_bus(bus: String) -> void:
	ui_sound_effects.bus = bus

func get_music_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(music.bus)))


func set_music_volume(volume_between_0_and_1: float) -> void:
	_show_shared_bus_warning()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(music.bus), linear_to_db(volume_between_0_and_1))


func play_music(resource: AudioStream, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play(resource, 0.0, crossfade_duration, override_bus)


func play_music_at_volume(resource: AudioStream, volume: float = 0.0, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play(resource, volume, crossfade_duration, override_bus)


func get_music_track_history() -> Array:
	return music.track_history


func get_last_played_music_track() -> String:
	return music.track_history[0]


func is_music_playing(resource: AudioStream = null) -> bool:
	return music.is_playing(resource)


func is_music_track_playing(resource_path: String) -> bool:
	return music.is_track_playing(resource_path)


func get_currently_playing_music() -> Array:
	return music.get_currently_playing()


func get_currently_playing_music_tracks() -> Array:
	return music.get_current_tracks()


func pause_music(resource: AudioStream = null) -> void:
	music.pause(resource)


func resume_music(resource: AudioStream = null) -> void:
	music.resume(resource)


func stop_music(fade_out_duration: float = 0.0) -> void:
	music.stop(fade_out_duration)


func set_default_music_bus(bus: String) -> void:
	music.bus = bus


### Helpers


func _show_shared_bus_warning() -> void:
	if music.bus == sound_effects.bus or music.bus == ui_sound_effects.bus:
		push_warning("Both music and sounds are using the same bus: %s" % music.bus)


### Custom Code goes here to make it easier to re-add after updates
var dialogue_process_mode: ProcessMode:
	set(value):
		dialogue.process_mode = value
	get:
		return dialogue.process_mode

var dialogue: MusicPlayer = MusicPlayer.new(["Dialogue"], 2)

func get_dialogue_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(music.bus)))


func set_dialogue_volume(volume_between_0_and_1: float) -> void:
	_show_shared_bus_warning()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(music.bus), linear_to_db(volume_between_0_and_1))


func play_dialogue(resource: AudioStream, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play(resource, 0.0, crossfade_duration, override_bus)


func play_dialogue_at_volume(resource: AudioStream, volume: float = 0.0, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	return music.play(resource, volume, crossfade_duration, override_bus)


func get_dialogue_track_history() -> Array:
	return music.track_history


func get_last_played_dialogue_track() -> String:
	return music.track_history[0]


func is_dialogue_playing(resource: AudioStream = null) -> bool:
	return music.is_playing(resource)


func is_dialogue_track_playing(resource_path: String) -> bool:
	return music.is_track_playing(resource_path)


func get_currently_playing_dialogue() -> Array:
	return dialogue.get_currently_playing()


func get_currently_playing_dialogue_tracks() -> Array:
	return dialogue.get_current_tracks()


func pause_dialogue(resource: AudioStream = null) -> void:
	dialogue.pause(resource)


func resume_dialogue(resource: AudioStream = null) -> void:
	dialogue.resume(resource)


func stop_dialogue(fade_out_duration: float = 0.0) -> void:
	dialogue.stop(fade_out_duration)

func set_default_dialogue_bus(bus: String) -> void:
	dialogue.bus = bus
