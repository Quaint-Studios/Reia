extends "./abstract_audio_player_pool.gd"


var track_history: PackedStringArray = []


func play(resource: AudioStream, position: float = 0.0, volume: float = 0.0, crossfade_duration: float = 0.0, override_bus: String = "") -> AudioStreamPlayer:
	stop(crossfade_duration * 2)

	var player = get_busy_player_with_resource(resource)

	# If the player already exists then just make sure the volume is right (it might have just been fading in or out)
	if player != null:
		fade_volume(player, player.volume_db, volume, crossfade_duration)
		return player

	# Otherwise we need to prep another player and handle its introduction
	player = prepare(resource, override_bus)
	fade_volume(player, -80.0, volume, crossfade_duration)

	# Remember this track name
	track_history.insert(0, resource.resource_path)
	if track_history.size() > 50:
		track_history.remove_at(50)

	player.call_deferred("play", position)
	return player


func is_playing(resource: AudioStream) -> bool:
	if resource != null:
		return get_busy_player_with_resource(resource) != null
	else:
		return busy_players.size() > 0


func stop(fade_out_duration: float = 0.0) -> void:
	for player in busy_players:
		if fade_out_duration <= 0.0:
			fade_out_duration = 0.01
		fade_volume(player, player.volume_db, -80, fade_out_duration)


func pause(resource: AudioStream = null) -> void:
	if resource != null:
		var player = get_busy_player_with_resource(resource)
		if is_instance_valid(player):
			player.stream_paused = true
	else:
		for player in busy_players:
			player.stream_paused = true


func resume(resource: AudioStream = null) -> void:
	if resource != null:
		var player = get_busy_player_with_resource(resource)
		if is_instance_valid(player):
			player.stream_paused = false
	else:
		for player in busy_players:
			player.stream_paused = false


func is_track_playing(resource_path: String) -> bool:
	for player in busy_players:
		if player.stream.resource_path == resource_path:
			return true
	return false


func get_currently_playing() -> Array[AudioStream]:
	var tracks: Array[AudioStream] = []
	for player in busy_players:
		tracks.append(player.stream)
	return tracks


func get_currently_playing_tracks() -> PackedStringArray:
	var tracks: PackedStringArray = []
	for player in busy_players:
		tracks.append(player.stream.resource_path)
	return tracks
