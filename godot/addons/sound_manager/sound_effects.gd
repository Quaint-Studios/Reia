extends "res://addons/sound_manager/abstract_audio_player_pool.gd"


func play(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	var player = prepare(resource, override_bus)
	player.call_deferred("play")
	return player
