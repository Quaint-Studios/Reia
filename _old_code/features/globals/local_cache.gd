extends Node

# Runtime references
var player_entity: Entity = null
var player_node: Node3D = null
var camera_global: CameraGlobal = CameraGlobal.new()

func _process(delta: float) -> void:
	camera_global.process(delta)

func _physics_process(delta: float) -> void:
	camera_global.physics_process(delta)

func set_player(entity: Entity) -> void:
	player_entity = entity
	player_node = entity as Node as Node3D

func set_camera_global(cam: CameraGlobal) -> void:
	camera_global = cam

func clear() -> void:
	player_entity = null
	player_node = null
	camera_global = null

func is_valid() -> bool:
	return player_node != null and player_entity != null and camera_global != null
