extends MarginContainer

@onready var player = owner as CharacterBody3D
@onready var camera = $PlayerMinimap/MapContainer/MapViewport/MinimapCamera as Camera3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	camera.global_position.x = player.global_position.x
	camera.global_position.z = player.global_position.z
