@tool
extends EditorScript

const SCREENS_DIR = "res://client/ui/screens/"
const OUT_SCREENS = "res://client/core/scenes.gd"

const ZONES_TXT = "res://core/features/spawning_and_zones/zones_list.txt"
const ZONES_INSTANCES_DIR = "res://shared_nodes/maps/instances/"
const ZONES_CHUNKED_DIR = "res://shared_nodes/maps/chunked/"
const OUT_ZONES = "res://core/features/spawning_and_zones/zone_registry.gd"

func _run() -> void:
	_generate_screens_registry()
	_generate_zones_registry()
	print("[RegistryBuilder] Successfully updated all Namespaces and Map Links!")

# ==========================================
# UI SCENE GENERATOR (Nested by Folder)
# ==========================================
func _generate_screens_registry() -> void:
	var code := "class_name Scenes\n\n## AUTO-GENERATED UI ROUTING\n"
	var dir := DirAccess.open(SCREENS_DIR)
	
	if dir:
		var err := dir.list_dir_begin()
		if err != OK:
			push_error("Failed to open screens directory: %s" % SCREENS_DIR)
			return
		var folder_name := dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				code += _process_ui_folder(SCREENS_DIR + folder_name + "/", folder_name)
			folder_name = dir.get_next()
			
	var out := FileAccess.open(OUT_SCREENS, FileAccess.WRITE)
	var success := out.store_string(code)
	if not success:
		print("[RegistryBuilder] Failed to write screens registry!")

func _process_ui_folder(path: String, folder_name: String) -> String:
	var sub_code := "class %s:\n" % folder_name.capitalize().replace(" ", "")
	var files := _get_files_in_dir(path, ".tscn")
	var known_names := {}
	
	for file in files:
		var raw_name := file.get_file().get_basename().to_upper()
		if known_names.has(raw_name): continue
			
		known_names[raw_name] = true
		var uid_str := ResourceUID.get_id_path(ResourceLoader.get_resource_uid(file))
		sub_code += "\tconst %s = \"%s\"\n" % [raw_name, uid_str]
		
	return sub_code + "\n"

# ==========================================
# ZONE GENERATOR (Handles Instances & Chunks)
# ==========================================
func _generate_zones_registry() -> void:
	var txt_file := FileAccess.open(ZONES_TXT, FileAccess.READ)
	var lines := txt_file.get_as_text().split("\n", false)
	
	var code_enum := "class_name Zone\n\n## AUTO-GENERATED ZONE IDS\nenum ID {\n"
	var code_instances := "## SINGLE INSTANCE MAPS (Hard Loads)\nconst MAP_PATHS = {\n"
	var code_chunks := "## SEAMLESS CHUNK DIRECTORIES (Streamed)\nconst CHUNK_DIRS = {\n"
	
	var known_hashes := {}
	
	for line in lines:
		var clean_name := line.strip_edges().to_upper()
		if clean_name.is_empty(): continue
		
		var hash_val := _hash_fnv1a_32(clean_name)
		if known_hashes.has(hash_val): continue
			
		known_hashes[hash_val] = true
		code_enum += "\t%s = %d,\n" % [clean_name, hash_val]
		
		# 1. Search for an Instance file (e.g., waterbrook.tscn)
		var instance_file := ZONES_INSTANCES_DIR + clean_name.to_lower() + ".tscn"
		if ResourceLoader.exists(instance_file):
			var uid_str := ResourceUID.get_id_path(ResourceLoader.get_resource_uid(instance_file))
			code_instances += "\tID.%s: \"%s\",\n" % [clean_name, uid_str]
			continue
			
		# 2. Search for a Chunked directory (e.g., ice_cave/)
		var chunk_dir := ZONES_CHUNKED_DIR + clean_name.to_lower() + "/"
		if DirAccess.dir_exists_absolute(chunk_dir):
			code_chunks += "\tID.%s: \"%s\",\n" % [clean_name, chunk_dir]
			continue
			
		# 3. Missing warning
		code_instances += "\t# MISSING MAP DATA FOR: %s\n" % clean_name

	var final_code := code_enum + "}\n\n" + code_instances + "}\n\n" + code_chunks + "}\n"
	
	var out := FileAccess.open(OUT_ZONES, FileAccess.WRITE)
	var success := out.store_string(final_code)
	if not success:
		push_error("[RegistryBuilder] Failed to write Zone Registry to file.")

func _hash_fnv1a_32(text: String) -> int:
	var hashValue: int = 2166136261
	for b in text.to_utf8_buffer():
		hashValue = (hashValue ^ b)
		hashValue = (hashValue * 16777619) & 0xFFFFFFFF
	return hashValue

func _get_files_in_dir(path: String, ext: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(path)
	if dir:
		var err := dir.list_dir_begin()
		if err != OK:
			push_error("Failed to open directory: %s" % path)
			return result
		var file := dir.get_next()
		while file != "":
			if not dir.current_is_dir() and file.ends_with(ext):
				result.append(path + file)
			file = dir.get_next()
	return result
