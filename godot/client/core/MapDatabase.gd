extends Node
## AUTOLOAD: MapDatabase
## Provides data-driven lookups pairing Zone IDs with Client-side resources.

const ZONE_DATA: Dictionary[Zone.ID, Dictionary] = {
	Zone.ID.WATERBROOK: {
		"music": "res://client/assets/audio/music/zones/waterbrook.ogg",
		"ambient": "res://client/assets/audio/ambient/nature.ogg"
	},
	#Zone.ID.ICE_CAVE: {
		#"music": "res://client/assets/audio/music/dungeon_theme.ogg",
		#"ambient": "res://client/assets/audio/ambient/wind_howl_ice_cave.ogg"
	#}
}

## Returns the audio stream path for a specific zone's background music.
func get_music_for_zone(zone_id: Zone.ID) -> AudioStream:
	return _get_asset(zone_id, "music")

## Returns the audio stream path for a specific zone's ambient noise.
func get_ambient_for_zone(zone_id: Zone.ID) -> AudioStream:
	return _get_asset(zone_id, "ambient")

## Helper to handle loading and null checks
func _get_asset(zone_id: Zone.ID, key: String) -> AudioStream:
	if ZONE_DATA.has(zone_id) and ZONE_DATA[zone_id].has(key):
		var path := (ZONE_DATA[zone_id] as Dictionary[String, String])[key]
		return load(path) as AudioStream # load() only hits the disk when called
	return null
