extends Node

## The purpose of this script is to manage scene transitions in a centralized way.
##
## Scene (.tscn): A Godot file. Everything visual is a scene.
##
## Screen: A specific type of Scene (e.g., login_screen.tscn). It is Client-Only.
## The server doesn't know it exists. It has no physics and no Zone ID.
##
## Map: A specific type of Scene (e.g., ice_cave.tscn). It is Shared. The client
## loads it to see the 3D meshes. The server loads it (headlessly) to calculate
## collision physics.
##
## Zone ID: The mathematical 32-bit hash (e.g., 83920112). This is the Server's
## nametag for a Map.

var _loading_screen := preload("res://client/ui/screens/menus/loading_screen.tscn")
var _current_ui_screen: Node = null
var _loading_target: String = ""

# ==========================================
# UI SCREEN ROUTING
# ==========================================
func transition_to_screen(screen_uid_path: String) -> void:
	if _current_ui_screen:
		_current_ui_screen.queue_free()
		
	var next_screen: Node = (load(screen_uid_path) as PackedScene).instantiate()
	# Add to a dedicated UI canvas layer, not the world root
	get_tree().root.get_node("ClientMain/UICanvas").add_child(next_screen)
	_current_ui_screen = next_screen

# ==========================================
# ZONE TELEPORTING (Hard Load)
# ==========================================
func teleport_to_zone(zone_id: int) -> void:
	var map_path = Zone.MAP_PATHS.get(zone_id)
	if not map_path:
		push_error("[SceneManager] Invalid Zone ID: %d" % zone_id)
		return
		
	_loading_target = map_path
	
	# Show loading screen
	var loader = _loading_screen.instantiate()
	get_tree().root.add_child(loader)
	
	# Flush current ECS World
	ECS.world.clear()
	
	# Begin Threaded Load
	ResourceLoader.load_threaded_request(_loading_target)
	set_process(true)

func _process(_delta: float) -> void:
	if _loading_target.is_empty():
		set_process(false)
		return
		
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(_loading_target, progress)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_map = ResourceLoader.load_threaded_get(_loading_target)
		get_tree().change_scene_to_packed(new_map)
		_loading_target = ""

# ==========================================
# CHUNK STREAMING (Seamless)
# ==========================================
func stream_chunk_additive(chunk_x: int, chunk_y: int) -> void:
	var path = "res://shared_nodes/maps/chunks/chunk_%d_%d.tscn" % [chunk_x, chunk_y]
	if ResourceLoader.exists(path):
		# We don't wipe the ECS here. We just append the node.
		var chunk = load(path).instantiate()
		chunk.name = "Chunk_%d_%d" % [chunk_x, chunk_y]
		get_tree().current_scene.add_child(chunk)

func unload_chunk(chunk_x: int, chunk_y: int) -> void:
	var chunk_name = "Chunk_%d_%d" % [chunk_x, chunk_y]
	var chunk = get_tree().current_scene.get_node_or_null(chunk_name)
	if chunk:
		chunk.queue_free()
