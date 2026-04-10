class_name ZoneAudioObserver extends Observer

func watch() -> Resource:
	return C_CurrentZone

func on_component_changed(entity: Entity, component: Resource, _prop: String, _new: Variant, _old: Variant) -> void:
	if not entity.has_component(C_LocalPlayer): return

	var zone := component as C_CurrentZone
	# MapDatabase pairs Zone.ID with audio stream paths
	print($"trying to get music for zone id {zone.zone_id}")
	var music_stream : AudioStream = MapDatabase.get_music_for_zone(zone.zone_id)
	var _player := SoundManager.play_music(music_stream, 2.0, "Music")
