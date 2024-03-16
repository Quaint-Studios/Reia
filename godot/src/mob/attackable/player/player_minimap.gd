class_name PlayerMinimap extends Control

@onready var player = owner as CharacterBody3D
@export var camera: Camera3D

func _ready() -> void:
	if camera == null:
		camera = get_node("MapContainer/MapViewport/MinimapCamera") as Camera3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
	minimap_follow()

func minimap_follow():
	camera.global_position.x = player.global_position.x
	camera.global_position.z = player.global_position.z
