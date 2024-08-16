class_name PlayerUI_Minimap extends Control
## This script keeps the minimap in sync with the player.

@onready var camera: Camera3D = %MinimapCamera

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	minimap_follow()

func minimap_follow() -> void:
	var player := PlayerManager.instance.player

	camera.global_position.x = player.global_position.x
	camera.global_position.z = player.global_position.z
