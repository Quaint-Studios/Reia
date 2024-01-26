extends Node


@export var default_busses := []
@export var default_pool_size := 8


var available_players: Array[AudioStreamPlayer] = []
var busy_players: Array[AudioStreamPlayer] = []
var bus: String = "Master"


func _init(possible_busses: PackedStringArray = default_busses, pool_size: int = default_pool_size) -> void:
	for possible_bus in possible_busses:
		var cases: PackedStringArray = [
			possible_bus,
			possible_bus.to_lower(),
			possible_bus.to_camel_case(),
			possible_bus.to_pascal_case(),
			possible_bus.to_snake_case()
		]
		for case in cases:
			if AudioServer.get_bus_index(case) > -1:
				bus = case
				break

	for i in pool_size:
		increase_pool()


func prepare(resource: AudioStream, override_bus: String = "") -> AudioStreamPlayer:
	var player := get_available_player()
	player.stream = resource
	player.bus = override_bus if override_bus != "" else bus
	player.volume_db = linear_to_db(1.0)
	player.pitch_scale = 1
	return player


func get_available_player() -> AudioStreamPlayer:
	if available_players.size() == 0:
		increase_pool()
	var player = available_players.pop_front()
	busy_players.append(player)
	return player


func mark_player_as_available(player: AudioStreamPlayer) -> void:
	if busy_players.has(player):
		busy_players.erase(player)

	if not available_players.has(player):
		available_players.append(player)


func increase_pool() -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	available_players.append(player)
	player.bus = bus
	player.finished.connect(_on_player_finished.bind(player))


### SIGNALS


func _on_player_finished(player: AudioStreamPlayer) -> void:
	mark_player_as_available(player)
