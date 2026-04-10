extends Node
## AUTOLOAD: MapDatabase
## Provides data-driven lookups pairing Zone IDs with Client-side resources.

## Returns the audio stream path for a specific zone's background music.
func get_music_for_zone(zone_id: int) -> AudioStream:
	match zone_id:
		Zone.ID.WATERBROOK:
			return preload("res://client/assets/audio/music/zones/waterbrook.ogg")
		#Zone.ID.ICE_CAVE:
			#return preload("res://client/assets/audio/music/dungeon_theme.ogg")
		_:
			return null # Fallback or silent

## Returns the audio stream path for a specific zone's ambient noise.
func get_ambient_for_zone(zone_id: int) -> AudioStream:
	match zone_id:
		Zone.ID.WATERBROOK:
			return preload("res://client/assets/audio/ambient/nature.ogg")
		#Zone.ID.ICE_CAVE:
			#return preload("res://client/assets/audio/ambient/wind_howl_ice_cave.ogg")
		_:
			return null
