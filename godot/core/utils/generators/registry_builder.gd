@tool
extends EditorScript

const SCREENS_DIR = "res://client/ui/screens/"
const OUT_SCREENS = "res://client/core/scenes.gd"

const ZONES_TXT = "res://core/features/spawning_and_zones/zones_list.txt"
const ZONES_INSTANCES_DIR = "res://shared_nodes/maps/instances/"
const ZONES_CHUNKED_DIR = "res://shared_nodes/maps/chunked/"
const OUT_ZONES = "res://core/features/spawning_and_zones/zone_registry.gd"

const OP_CODES_TXT = "res://core/features/network/op_codes_list.txt"
const OUT_GD_OP_CODES = "res://core/features/network/op_codes.gd"
var OUT_RUST_OP_CODES := ProjectSettings.globalize_path("res://").path_join("../rust/src/net/op_codes.rs")

func _run() -> void:
	_generate_screens_registry()
	_generate_zones_registry()
	_generate_opcodes_registry()
	print("[RegistryBuilder] Successfully updated UI, Zones, and Dual-Language OpCodes!")

# ==========================================
# OP CODE GENERATOR (Rust + Godot)
# ==========================================
func _generate_opcodes_registry() -> void:
	if not FileAccess.file_exists(OP_CODES_TXT):
		push_warning("[RegistryBuilder] Missing op_codes_list.txt. Skipping.")
		return

	var txt_file := FileAccess.open(OP_CODES_TXT, FileAccess.READ)
	var lines := txt_file.get_as_text().split("\n", false)

	var gd_code := "class_name OpCode\n\n## AUTO-GENERATED NETWORK OP CODES\nenum ID {\n"
	var rust_code := "// AUTO-GENERATED NETWORK OP CODES\n// Do not edit manually. Run registry_builder.gd in Godot.\n\n"
	rust_code += "#[repr(u16)]\n";
	rust_code += "#[derive(Debug, Clone, Copy, PartialEq, Eq)]\n";
	rust_code += "pub enum OpCode {\n"

	var rust_match_arms := ""
	var known_hashes := {}

	for line in lines:
		var clean_name := line.strip_edges().to_upper()
		if clean_name.is_empty() or clean_name.begins_with("#"): continue

		var hash_val := _hash_16(clean_name)
		if known_hashes.has(hash_val):
			push_warning("[RegistryBuilder] Hash collision detected for op code: %s (hash: %d)" % [clean_name, hash_val])
			continue

		known_hashes[hash_val] = true

		# Write to Godot format (SCREAMING_SNAKE_CASE)
		gd_code += "\t%s = %d,\n" % [clean_name, hash_val]

		# Write to Rust format (PascalCase)
		var rust_variant := clean_name.to_pascal_case()
		rust_code += "    %s = %d,\n" % [rust_variant, hash_val]

		# Build the safe parsing match arm
		rust_match_arms += "            %d => Ok(OpCode::%s),\n" % [hash_val, rust_variant]

	gd_code += "}\n"

	# Finish the Rust TryFrom implementation
	rust_code += "}\n\n"
	rust_code += "impl TryFrom<u16> for OpCode {\n"
	rust_code += "    type Error = ();\n"
	rust_code += "    fn try_from(v: u16) -> Result<Self, Self::Error> {\n"
	rust_code += "        match v {\n"
	rust_code += rust_match_arms
	rust_code += "            _ => Err(()),\n"
	rust_code += "        }\n"
	rust_code += "    }\n"
	rust_code += "}\n"

	# Save GDScript file
	var gd_out := FileAccess.open(OUT_GD_OP_CODES, FileAccess.WRITE)
	var success_gd := gd_out.store_string(gd_code)
	if not success_gd:
		push_error("[RegistryBuilder] Failed to write OpCode registry to Godot file.")

	# Save Rust file (using absolute OS path to break out of res:// restrictions)
	var rust_out := FileAccess.open(OUT_RUST_OP_CODES, FileAccess.WRITE)
	if rust_out:
		var success_rust := rust_out.store_string(rust_code)
		if not success_rust:
			push_error("[RegistryBuilder] Failed to write to Rust backend path: " + OUT_RUST_OP_CODES)
	else:
		push_error("[RegistryBuilder] Failed to open Rust backend path: " + OUT_RUST_OP_CODES)

# ==========================================
# UI SCENE GENERATOR (Nested by Folder)
# ==========================================
func _generate_screens_registry() -> void:
	var code := "class_name Scenes\n\n## AUTO-GENERATED UI ROUTING\n"
	var dir := DirAccess.open(SCREENS_DIR)

	if dir:
		var err := dir.list_dir_begin()
		if err != OK:
			push_error("[RegistryBuilder] Failed to open screens directory: %s" % SCREENS_DIR)
			return
		var folder_name := dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				code += _process_ui_folder(SCREENS_DIR + folder_name + "/", folder_name)
			folder_name = dir.get_next()

	var out := FileAccess.open(OUT_SCREENS, FileAccess.WRITE)
	var success := out.store_string(code)
	if not success:
		push_error("[RegistryBuilder] Failed to write screens registry!")

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

	return sub_code

# ==========================================
# ZONE GENERATOR (Handles Instances & Chunks)
# ==========================================
func _generate_zones_registry() -> void:
	if not FileAccess.file_exists(ZONES_TXT):
		push_error("[RegistryBuilder] Zones list file not found: %s" % ZONES_TXT)
		return

	var txt_file := FileAccess.open(ZONES_TXT, FileAccess.READ)
	var lines := txt_file.get_as_text().split("\n", false)

	var code_enum := "class_name Zone\n\n## AUTO-GENERATED ZONE IDS\nenum ID {\n"
	var code_instances := "## SINGLE INSTANCE MAPS (Hard Loads)\nconst MAP_PATHS: Dictionary[int, String] = {\n"
	var code_chunks := "## SEAMLESS CHUNK DIRECTORIES (Streamed)\nconst CHUNK_DIRS: Dictionary[int, String] = {\n"

	var known_hashes := {}

	for line in lines:
		var clean_name := line.strip_edges().to_upper()
		if clean_name.is_empty() or clean_name.begins_with("#"): continue

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

func _hash_16(text: String) -> int:
	var hash_32: int = _hash_fnv1a_32(text)
	# XOR folding compresses the 32-bit FNV-1a hash into 16 bits safely
	# to guarantee it fits into a u16 for the network.
	return (hash_32 ^ (hash_32 >> 16)) & 0xFFFF

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
