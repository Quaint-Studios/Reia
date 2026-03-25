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

# State for Instance Loading
var _loading_target: String = ""

# State for Chunk Streaming
var _active_chunk_dir: String = ""
var _loaded_chunks: Dictionary[String, Node] = {}

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
	# Check if it's a single instanced map (like Waterbrook Town)
	if Zone.MAP_PATHS.has(zone_id):
		_hard_load_instance(Zone.MAP_PATHS[zone_id])
		return

	# Check if it's a chunked directory (like Ice Cave or Jadewater Falls)
	if Zone.CHUNK_DIRS.has(zone_id):
		_start_chunk_streaming(Zone.CHUNK_DIRS[zone_id])
		return

	push_error("[SceneManager] Invalid Zone ID: %d" % zone_id)

# --- INSTANCE LOADING (Hard Load) ---
func _hard_load_instance(map_uid: String) -> void:
	_loading_target = map_uid
	_active_chunk_dir = "" # Disable chunking

	var loader := _loading_screen.instantiate()
	get_tree().root.add_child(loader)

	ECS.world.purge()

	ResourceLoader.load_threaded_request(_loading_target)
	set_process(true)

func _process(_delta: float) -> void:
	if _loading_target.is_empty():
		set_process(false)
		return

	var progress := []
	var status := ResourceLoader.load_threaded_get_status(_loading_target, progress)

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_map := ResourceLoader.load_threaded_get(_loading_target) as PackedScene
		var err := get_tree().change_scene_to_packed(new_map)
		if err != OK:
			push_error("[SceneManager] Failed to change scene to '%s' (err=%d)" % [_loading_target, err])
		else:
			print("[SceneManager] Successfully loaded scene: %s" % _loading_target)

		_loading_target = ""

# ==========================================
# CHUNK STREAMING (Seamless)
# ==========================================
func _start_chunk_streaming(chunk_dir: String) -> void:
	_loading_target = "" # Ensure hard loader is off
	_active_chunk_dir = chunk_dir

	# Normally you would load chunk_0_0 as the entry point here,
	# and a separate System/Observer tracks player coordinates to load adjacent chunks.
	stream_chunk_additive(0, 0)

func stream_chunk_additive(chunk_x: int, chunk_y: int) -> void:
	if _active_chunk_dir.is_empty(): return

	var chunk_name := "chunk_%d_%d" % [chunk_x, chunk_y]
	if _loaded_chunks.has(chunk_name): return

	var path := _active_chunk_dir + chunk_name + ".tscn"
	if ResourceLoader.exists(path):
		var chunk := (load(path) as PackedScene).instantiate()
		chunk.name = chunk_name
		get_tree().current_scene.add_child(chunk)
		_loaded_chunks[chunk_name] = chunk

func unload_chunk(chunk_x: int, chunk_y: int) -> void:
	var chunk_name := "chunk_%d_%d" % [chunk_x, chunk_y]
	if _loaded_chunks.has(chunk_name):
		_loaded_chunks[chunk_name].queue_free()
		var success := _loaded_chunks.erase(chunk_name)
		if not success:
			push_error("[SceneManager] Failed to unload chunk '%s'" % chunk_name)
