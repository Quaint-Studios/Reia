extends "./abstract_audio_player_pool.gd"


func play(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	var player = prepare(resource, override_bus)
	player.call_deferred("play")
	return player


func stop(resource: AudioStream) -> void:
	for player in busy_players:
		if player.stream == resource:
			player.call_deferred("stop")
