@tool
extends EditorScript

const SCREENS_DIR = "res://client/ui/screens/"
const OUT_SCREENS = "res://client/core/scenes.gd"

const ZONES_TXT = "res://core/features/spawning_and_zones/zones_list.txt"
const ZONES_MAPS_DIR = "res://shared_nodes/maps/dungeons/"
const OUT_ZONES = "res://core/features/spawning_and_zones/zone_registry.gd"

func _run() -> void:
	_generate_screens_registry()
	_generate_zones_registry()
	print("[RegistryBuilder] Successfully updated all Namespaces!")

# ==========================================
# UI SCENE GENERATOR (Nested by Folder)
# ==========================================
func _generate_screens_registry() -> void:
	var code := "class_name Scenes\n\n## AUTO-GENERATED UI ROUTING\n"
	var dir := DirAccess.open(SCREENS_DIR)
	
	if dir:
		var err := dir.list_dir_begin()
		if err != OK:
			push_error("[RegistryBuilder] Failed to open directory: %s" % SCREENS_DIR)
			return
		var folder_name := dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				code += _process_ui_folder(SCREENS_DIR + folder_name + "/", folder_name)
			folder_name = dir.get_next()
			
	var out := FileAccess.open(OUT_SCREENS, FileAccess.WRITE)
	var success := out.store_string(code)
	if success:
		print("[RegistryBuilder] Successfully updated Scenes.gd")
	else:
		push_error("[RegistryBuilder] Failed to write to file: %s" % OUT_SCREENS)

func _process_ui_folder(path: String, folder_name: String) -> String:
	var sub_code := "class %s:\n" % folder_name.capitalize().replace(" ", "")
	var files := _get_files_in_dir(path, ".tscn")
	var known_names := {}
	
	for file in files:
		var raw_name := file.get_file().get_basename().to_upper()
		
		# Conflict Resolution & Warning!
		if known_names.has(raw_name):
			push_warning("[RegistryBuilder] CONFLICT DETECTED: '%s' in folder '%s'. Skipping duplicate." % [raw_name, folder_name])
			continue
			
		known_names[raw_name] = true
		var uid_str := ResourceUID.get_id_path(ResourceLoader.get_resource_uid(file))
		sub_code += "\tconst %s = \"%s\"\n" % [raw_name, uid_str]
		
	return sub_code + "\n"

# ==========================================
# ZONE GENERATOR (Deterministic Hashes)
# ==========================================
func _generate_zones_registry() -> void:
	var txt_file := FileAccess.open(ZONES_TXT, FileAccess.READ)
	var lines := txt_file.get_as_text().split("\n", false)
	
	var code := "class_name Zone\n\n## AUTO-GENERATED ZONE IDS (SERVER/DB)\nenum ID {\n"
	var map_dict := "## CLIENT MAP ROUTING\nconst MAP_PATHS = {\n"
	var known_hashes := {}
	
	for line in lines:
		var clean_name := line.strip_edges().to_upper()
		if clean_name.is_empty(): continue
		
		var hash_val := _hash_fnv1a_32(clean_name)
		
		if known_hashes.has(hash_val):
			push_error("[RegistryBuilder] HASH COLLISION OR DUPLICATE: %s" % clean_name)
			continue
			
		known_hashes[hash_val] = true
		code += "\t%s = %d,\n" % [clean_name, hash_val]
		
		# Look for matching map file
		var map_file := ZONES_MAPS_DIR + clean_name.to_lower() + ".tscn"
		if ResourceLoader.exists(map_file):
			var uid_str := ResourceUID.get_id_path(ResourceLoader.get_resource_uid(map_file))
			map_dict += "\tID.%s: \"%s\",\n" % [clean_name, uid_str]
		else:
			map_dict += "\t# Missing Map File for: %s\n" % clean_name
			
	code += "}\n\n" + map_dict + "}\n"
	
	var out := FileAccess.open(OUT_ZONES, FileAccess.WRITE)
	var success := out.store_string(code)
	if success:
		print("[RegistryBuilder] Successfully updated ZoneRegistry.gd")
	else:
		push_error("[RegistryBuilder] Failed to write to file: %s" % OUT_ZONES)

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
			push_error("[RegistryBuilder] Failed to open directory: %s" % path)
			return result

		var file := dir.get_next()
		while file != "":
			if not dir.current_is_dir() and file.ends_with(ext):
				result.append(path + file)
			file = dir.get_next()
	return result
