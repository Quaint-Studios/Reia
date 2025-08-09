@tool
extends EditorImportPlugin
class_name AutoGLBTextureSorterImporter

#region Configuration
const MODELS_ROOT: String = "res://assets/models/"
const TEXTURES_ROOT: String = "res://assets/textures/"
const LOG_PATH: String = "res://tools/auto_asset_sorter/auto_asset_sorter.log"
const LOG_NAME: String = "AutoAssetSortImport"

const SECTIONS: PackedStringArray = ["effects", "enemies", "npcs", "player", "props", "spirits", "skyboxes"]

const IMAGE_EXTS: PackedStringArray = [
	".png", ".jpg", ".jpeg", ".tga", ".bmp", ".webp", ".dds", ".exr", ".hdr", ".ktx", ".ktx2"
]

const PATCHABLE_TEXT_EXTS: PackedStringArray = [
	".tscn", ".scn", ".tres", ".material", ".import", ".gdshader", ".shader", ".theme"
]

enum CollisionStrategy {SKIP, OVERWRITE, INCREMENT}

var logger: Logger
#endregion

#region Importer Functions
func _init() -> void:
	logger = Logger.new(LOG_PATH, LOG_NAME)

func _get_importer_name() -> String:
	return "auto_glb_texture_sorter"

func _get_visible_name() -> String:
	return "GLB (Auto Texture Sort)"

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["glb"])

func _get_save_extension() -> String:
	return "tscn"

func _get_resource_type() -> String:
	return "PackedScene"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(_preset_index: int) -> String:
	return "Default"

func _get_import_options(_path: String, _preset_index: int) -> Array:
	return [
		{
			"name": "collision_strategy",
			"default_value": CollisionStrategy.INCREMENT,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Skip,Overwrite,Increment"
		},
		{
			"name": "enable_reference_patch",
			"default_value": false
		},
		{
			"name": "dry_run",
			"default_value": false
		},
		{
			"name": "log_verbose",
			"default_value": true
		}
	]

func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true

# Higher than built-in glTF importer so ours is selected automatically.
func _get_priority() -> float:
	return 100.0

# If you want to run after built-ins anyway, adjust order (default 0). >0 runs later.
func _get_import_order() -> int:
	return 1

# Increment when changing output format logic to force reimport.
func _get_format_version() -> int:
	return 1

# Not thread-safe while moving files & patching references.
func _can_import_threaded() -> bool:
	return false
#endregion

#region Core Functionality
func _import(source_file: String, save_path: String, options: Dictionary, _platform_variants: Array, _gen_files: Array) -> int:
	if not Engine.is_editor_hint():
		return ERR_UNAUTHORIZED
	
	var section: String = _detect_section(source_file)
	# TODO: Look into getting the proper types here.
	var collision_strategy: int = int(options.get("collision_strategy", CollisionStrategy.INCREMENT))
	var do_patch: bool = bool(options.get("enable_reference_patch", false))
	var dry_run: bool = bool(options.get("dry_run", false))
	var verbose: bool = bool(options.get("log_verbose", true))
	
	_log("IMPORT START: %s (section=%s)" % [source_file, section], verbose)

	var result := append_import_external_resource(
		source_file,
		{}, # custom options if needed
		"scene"
	)
	if result != OK:
		_log("ERROR: Built-in scene import failed.", true)
		return result
	
	var packed_scene: PackedScene = ResourceLoader.load(source_file)
	if packed_scene == null:
		_log("ERROR: Failed to load GLB as PackedScene: %s" % source_file, true)
		return ERR_CANT_OPEN
	
	var texture_paths: Array[String] = _collect_external_texture_paths(packed_scene)
	if texture_paths.is_empty():
		_log("No external textures found.", verbose)
	else:
		_log("Found %d external textures." % texture_paths.size(), verbose)
	
	var relocation_map: Dictionary = {}
	for tex_path: String in texture_paths:
		var new_path: String = _compute_target_path(tex_path, section)
		if tex_path == new_path:
			continue
		var final_dest: String = _handle_collision_and_move(tex_path, new_path, collision_strategy, dry_run, verbose)
		if final_dest != "":
			relocation_map[tex_path] = final_dest
	
	if relocation_map.is_empty():
		_log("No textures moved.", verbose)
	else:
		_log("Relocated %d textures." % relocation_map.size(), true)
	
	if not relocation_map.is_empty():
		_update_scene_material_texture_paths(packed_scene, relocation_map, verbose)
	
	if do_patch and not relocation_map.is_empty() and not dry_run:
		_patch_references(relocation_map, verbose)
	
	var scene_save_path: String = "%s.%s" % [save_path, _get_save_extension()]
	var save_err: Error = ResourceSaver.save(packed_scene, scene_save_path)
	if save_err != OK:
		_log("ERROR: Failed to save scene: %s (err=%d)" % [scene_save_path, save_err], true)
		return save_err
	
	_log("IMPORT COMPLETE: %s -> %s" % [source_file, scene_save_path], true)
	
	# TODO: This needs to be a button in the importer in the future.
	# _deferred_filesystem_scan.call_deferred()

	return OK

func _deferred_filesystem_scan() -> void:
	var editor_fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	if editor_fs:
		editor_fs.scan()
#endregion

#region Section / Path Helpers
func _detect_section(glb_path: String) -> String:
	if not glb_path.begins_with(MODELS_ROOT):
		return ""
	var rel: String = glb_path.substr(MODELS_ROOT.length())
	for s: String in SECTIONS:
		if rel == s or rel.begins_with(s + "/"):
			return s
	return ""

func _compute_target_path(src_tex_path: String, section: String) -> String:
	if section == "":
		return src_tex_path
	return TEXTURES_ROOT + section + "/" + src_tex_path.get_file()
#endregion

#region Texture Collection
func _collect_external_texture_paths(scene: PackedScene) -> Array[String]:
	var out: Array[String] = []
	var root: Node = scene.instantiate()
	if root == null:
		return out
	var queue: Array[Node] = [root]
	while not queue.is_empty():
		var n: Node = queue.pop_back()
		for child: Node in n.get_children():
			queue.append(child)
		if n is MeshInstance3D:
			_collect_from_meshinstance(n as MeshInstance3D, out)
		elif n is MultiMeshInstance3D:
			_collect_from_multimeshinstance(n as MultiMeshInstance3D, out)
	root.queue_free()
	return out

func _collect_from_meshinstance(mi: MeshInstance3D, out: Array[String]) -> void:
	var mesh: Mesh = mi.mesh
	if mesh == null:
		return
	var surface_count: int = mesh.get_surface_count()
	for i in surface_count:
		var mat: Material = mesh.surface_get_material(i)
		if mat:
			_collect_material_textures(mat, out)

func _collect_from_multimeshinstance(mmi: MultiMeshInstance3D, out: Array[String]) -> void:
	var mat: Material = mmi.material
	if mat:
		_collect_material_textures(mat, out)

func _collect_material_textures(mat: Material, out: Array[String]) -> void:
	var plist: Array = mat.get_property_list()
	for prop: Dictionary in plist:
		if not prop.has("name"):
			continue
		var name: String = prop.name
		var value: Variant = mat.get(name)
		if value is Texture2D:
			var tex: Texture2D = value
			var path: String = tex.resource_path
			if path != "" and path.begins_with("res://"):
				for ext in IMAGE_EXTS:
					if path.ends_with(ext):
						if not path in out:
							out.append(path)
						break
#endregion

#region Move / Collision Logic
func _handle_collision_and_move(src: String, dst: String, strategy: int, dry_run: bool, verbose: bool) -> String:
	if src == dst:
		return src
	if not FileAccess.file_exists(src):
		_log("WARN: Source file does not exist: %s" % src, true)
		var dir_path: String = src.get_base_dir()
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var files: Array[String] = []
			while true:
				var fname: String = dir.get_next()
				if fname == "":
					break
				if not dir.current_is_dir():
					files.append(dir_path + "/" + fname)
			dir.list_dir_end()
			_log("Files in directory: %s" % files, true)
		_log("WARN: Source missing (skip): %s" % src, true)
		return ""
	var final_dst: String = dst
	if FileAccess.file_exists(dst):
		match strategy:
			CollisionStrategy.SKIP:
				_log("Collision skip: %s" % dst, verbose)
				return ""
			CollisionStrategy.OVERWRITE:
				pass
			CollisionStrategy.INCREMENT:
				final_dst = _increment_path(dst)
			_:
				_log("WARN: Unknown collision strategy for %s" % dst, true)
				return ""
	if dry_run:
		_log("DRY RUN: %s -> %s" % [src, final_dst], true)
		return final_dst
	
	var dst_dir: String = final_dst.get_base_dir()
	var mk_err: int = DirAccess.make_dir_recursive_absolute(dst_dir)
	if mk_err != OK and mk_err != ERR_ALREADY_EXISTS:
		_log("ERROR: mkdir failed (%d): %s" % [mk_err, dst_dir], true)
		return ""
	
	var copy_err: int = DirAccess.copy_absolute(src, final_dst)
	if copy_err != OK:
		_log("ERROR: Copy failed (%d): %s -> %s" % [copy_err, src, final_dst], true)
		return ""
	var rm_err: int = DirAccess.remove_absolute(src)
	if rm_err != OK:
		_log("WARN: Remove source failed (%d): %s" % [rm_err, src], true)
	
	_move_sidecar_import(src, final_dst)
	_log("MOVE: %s -> %s" % [src, final_dst], true)
	return final_dst

func _increment_path(base_path: String) -> String:
	var dir: String = base_path.get_base_dir()
	var file: String = base_path.get_file()
	var stem: String = file.get_basename()
	var ext: String = file.get_extension()
	var i: int = 1
	var candidate: String = "%s/%s (%d).%s" % [dir, stem, i, ext]
	while FileAccess.file_exists(candidate):
		i += 1
		candidate = "%s/%s (%d).%s" % [dir, stem, i, ext]
	return candidate

func _move_sidecar_import(old_img: String, new_img: String) -> void:
	var old_meta: String = old_img + ".import"
	if not FileAccess.file_exists(old_meta):
		return
	var new_meta: String = new_img + ".import"
	var copy_err: int = DirAccess.copy_absolute(old_meta, new_meta)
	if copy_err == OK:
		var rm_err: int = DirAccess.remove_absolute(old_meta)
		if rm_err != OK:
			_log("WARN: Sidecar remove failed (%d): %s" % [rm_err, old_meta], true)
	else:
		_log("WARN: Sidecar copy failed (%d): %s" % [copy_err, old_meta], true)
#endregion

#region Scene Material Update
func _update_scene_material_texture_paths(scene: PackedScene, relocation: Dictionary, verbose: bool) -> void:
	var inst: Node = scene.instantiate()
	if inst == null:
		return
	var queue: Array[Node] = [inst]
	var changed_count: int = 0
	while not queue.is_empty():
		var n: Node = queue.pop_back()
		for child: Node in n.get_children():
			queue.append(child)
		if n is MeshInstance3D:
			changed_count += _retarget_mesh_textures(n as MeshInstance3D, relocation)
		elif n is MultiMeshInstance3D:
			changed_count += _retarget_multimesh_textures(n as MultiMeshInstance3D, relocation)
	var __ := scene.pack(inst)
	inst.queue_free()
	_log("Retargeted %d material(s)." % changed_count, verbose)

func _retarget_mesh_textures(mi: MeshInstance3D, relocation: Dictionary) -> int:
	var mesh: Mesh = mi.mesh
	if mesh == null:
		return 0
	var changed: int = 0
	var count: int = mesh.get_surface_count()
	for i in count:
		var mat: Material = mesh.surface_get_material(i)
		if mat and _retarget_material(mat, relocation):
			changed += 1
	return changed

func _retarget_multimesh_textures(mmi: MultiMeshInstance3D, relocation: Dictionary) -> int:
	var mat: Material = mmi.material
	if mat and _retarget_material(mat, relocation):
		return 1
	return 0

func _retarget_material(mat: Material, relocation: Dictionary) -> bool:
	var modified: bool = false
	var plist: Array = mat.get_property_list()
	for p: Dictionary in plist:
		if not p.has("name"):
			continue
		var name: String = p.name
		var val: Variant = mat.get(name)
		if val is Texture2D:
			var tex: Texture2D = val
			var old_path: String = tex.resource_path
			if relocation.has(old_path):
				var new_path: String = relocation[old_path]
				var new_tex: Texture2D = ResourceLoader.load(new_path)
				if new_tex:
					mat.set(name, new_tex)
					modified = true
	return modified
#endregion

#region Reference Patching
func _patch_references(relocation: Dictionary[String, String], verbose: bool) -> void:
	var files: PackedStringArray = _gather_project_files(PATCHABLE_TEXT_EXTS)
	var total_hits: int = 0
	for f in files:
		if not FileAccess.file_exists(f):
			continue
		var fa: FileAccess = FileAccess.open(f, FileAccess.READ)
		if fa == null:
			continue
		var content: String = fa.get_as_text()
		fa.close()
		var original: String = content
		for old_path: String in relocation.keys():
			var new_path: String = relocation[old_path]
			if content.contains(old_path):
				content = content.replace(old_path, new_path)
		if content != original:
			var fw: FileAccess = FileAccess.open(f, FileAccess.WRITE)
			if fw:
				var __ := fw.store_string(content)
				fw.close()
				total_hits += 1
				_log("PATCH: %s" % f, verbose)
	if total_hits == 0:
		_log("PATCH: No external references updated.", verbose)
	else:
		_log("PATCH: Updated %d file(s)." % total_hits, true)

func _gather_project_files(exts: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = []
	_scan_dir_recursive("res://", exts, out)
	return out

func _scan_dir_recursive(path: String, exts: PackedStringArray, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	var __ := dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full: String = path + name
		if dir.current_is_dir():
			_scan_dir_recursive(full + "/", exts, out)
		else:
			for ext in exts:
				if full.ends_with(ext):
					var ___ := out.append(full)
					break
	dir.list_dir_end()
#endregion

#region Logging 
func _log(msg: String, force: bool) -> void:
	if not force:
		return
	print("[%s] %s" % [LOG_NAME, msg])
	logger.log(msg)
#endregion