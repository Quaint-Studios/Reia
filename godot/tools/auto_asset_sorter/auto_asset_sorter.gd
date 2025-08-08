@tool
extends Node

# ---------------- Configuration ----------------
const SECTIONS: PackedStringArray = ["effects", "enemies", "npcs", "player", "props", "spirits", "skyboxes"]
const MODELS_ROOT: String = "res://assets/models/"
const TEXTURES_ROOT: String = "res://assets/textures/"
const LOG_PATH: String = "res://tools/auto_asset_sorter/auto_asset_sorter.log"
const LOG_NAME: String = "AutoAssetSorter"

const SUPPORTED_IMAGE_EXTS: PackedStringArray = [
    ".png", ".jpg", ".jpeg", ".tga", ".bmp", ".webp", ".dds", ".exr", ".hdr"
]

# Text-based resource types we will patch. (Binary .glb is excluded intentionally.)
const TEXT_REFERENCE_EXTS: PackedStringArray = [
    ".tscn", ".scn", ".tres", ".res", ".material", ".import", ".gdshader", ".shader", ".theme"
]

# ---------------- State ----------------
var logger: Logger
var _last_handled_glb: String = ""
var _pending_moves: Array[Dictionary] = [] # Each: { src_path, dest_dir, section }
var _is_processing_queue: bool = false
var _batched_reimport: PackedStringArray = []
var _cached_project_files: PackedStringArray = []
var _cached_scan_generation: int = 0
var _last_fs_version: int = -1

# Performance knob: full rescan every N patch cycles to avoid stale cache.
const RESCAN_INTERVAL: int = 25
var _patch_cycles: int = 0

# ---------------- Lifecycle ----------------
func _ready() -> void:
    if not Engine.is_editor_hint():
        queue_free()
        return
    logger = Logger.new(LOG_PATH, LOG_NAME)
    logger.print("Initialized.")
    var editor_fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
    if not editor_fs.resources_reimported.is_connected(_on_resources_reimported):
        var __ := editor_fs.resources_reimported.connect(_on_resources_reimported)

func _exit_tree() -> void:
    if not Engine.is_editor_hint():
        return
    var editor_fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
    if editor_fs.resources_reimported.is_connected(_on_resources_reimported):
        editor_fs.resources_reimported.disconnect(_on_resources_reimported)

# ---------------- Import Handling ----------------
func _on_resources_reimported(resources: PackedStringArray) -> void:
    for resource_path: String in resources:
        if resource_path.ends_with(".glb") and resource_path.begins_with(MODELS_ROOT):
            var section: String = _get_section_from_path(resource_path)
            if section != "":
                _last_handled_glb = resource_path
                logger.print("GLB Reimported detected: %s (section=%s)" % [resource_path, section])
                _handle_glb_import(resource_path, section)

func _get_section_from_path(path: String) -> String:
    if not path.begins_with(MODELS_ROOT):
        return ""
    var rel_path: String = path.substr(MODELS_ROOT.length())
    for section: String in SECTIONS:
        if rel_path.begins_with(section + "/") or rel_path == section:
            return section
    return ""

func _handle_glb_import(glb_path: String, section: String) -> void:
    logger.print("Handling GLB import: %s in section: %s" % [glb_path, section])
    var referenced_textures: Array[String] = _extract_referenced_textures(glb_path)
    if referenced_textures.is_empty():
        logger.print("No external textures detected for: %s" % glb_path)
        return
    for tex_path: String in referenced_textures:
        logger.print("Reference: %s" % tex_path)
        _enqueue_texture_move(tex_path, section)
    _process_move_queue() # Start processing if idle.

# ---------------- Dependency Extraction ----------------
func _extract_referenced_textures(glb_path: String) -> Array[String]:
    var deps: PackedStringArray = ResourceLoader.get_dependencies(glb_path)
    var textures: Array[String] = []
    for raw_dep: String in deps:
        # Godot dependency format example:
        # uid://abcdefghijklmno::res://assets/textures/foo/albedo.png::<subresource>
        var path_slice: String = raw_dep.get_slice("::", 2)
        if path_slice == "":
            # Fallback if unexpected format; attempt to use raw_dep itself.
            path_slice = raw_dep
        var resolved_path: String = _normalize_dependency_path(path_slice, raw_dep)
        if resolved_path == "":
            continue
        for ext in SUPPORTED_IMAGE_EXTS:
            if resolved_path.ends_with(ext) and FileAccess.file_exists(resolved_path):
                textures.append(resolved_path)
                break
    return textures

func _normalize_dependency_path(candidate_path: String, raw_dep: String) -> String:
    # If candidate already looks like a path and exists, accept.
    if candidate_path.begins_with("res://"):
        return candidate_path
    # If the raw_dep begins with a UID, try resolve that UID to a path (rare case where slice parsing failed).
    if raw_dep.begins_with("uid://"):
        var uid_text: String = raw_dep.get_slice("::", 0)
        var uid: int = ResourceUID.text_to_id(uid_text)
        if uid != 0:
            var mapped: String = ResourceUID.get_id_path(uid)
            return mapped
    return ""

# ---------------- Move Queue ----------------
func _enqueue_texture_move(src_path: String, section: String) -> void:
    _pending_moves.append({
        "src_path": src_path,
        "section": section,
        "dest_dir": TEXTURES_ROOT + section + "/"
    })

func _process_move_queue() -> void:
    if _is_processing_queue or _pending_moves.is_empty():
        return
    _is_processing_queue = true
    _process_next_move()

func _process_next_move() -> void:
    if _pending_moves.is_empty():
        _is_processing_queue = false
        _schedule_reimport_flush()
        return
    var entry: Dictionary = _pending_moves.pop_front()
    var src_path: String = entry.src_path
    var section: String = entry.section
    var dest_dir: String = entry.dest_dir
    var tex_name: String = src_path.get_file()
    var dest_path: String = dest_dir + tex_name
    # Already in correct directory?
    if src_path.begins_with(dest_dir):
        logger.print("Already in correct section: %s" % src_path)
        call_deferred("_process_next_move")
        return
    if not FileAccess.file_exists(dest_path):
        # Confirmation dialog
        Dialogs.show_confirm_move(tex_name, src_path, dest_path, func(s: String, d: String, confirmed: bool) -> void:
            _on_texture_move_confirmed(s, d, confirmed)
        )
    else:
        # Collision dialog
        Dialogs.show_collision_dialog(tex_name, src_path, dest_dir, func(s: String, dd: String, action: String) -> void:
            _on_texture_collision_resolved(s, dd, action)
        )

# ---------------- Move / Collision Handling ----------------
func _on_texture_move_confirmed(src_path: String, dest_path: String, confirmed: bool) -> void:
    if not confirmed:
        logger.print("SKIP: %s -> %s | User cancelled move." % [src_path, dest_path])
        call_deferred("_process_next_move")
        return
    if _move_file(src_path, dest_path):
        logger.print("MOVE: %s -> %s" % [src_path, dest_path])
        _after_texture_moved(src_path, dest_path)
    else:
        logger.print("ERROR: %s -> %s | Failed to move." % [src_path, dest_path])
    call_deferred("_process_next_move")

func _on_texture_collision_resolved(src_path: String, dest_dir: String, action: String) -> void:
    var tex_name: String = src_path.get_file()
    var dest_path: String = dest_dir + tex_name
    match action:
        "cancel":
            logger.log("SKIP: %s -> %s | Collision cancelled." % [src_path, dest_path])
        "overwrite":
            if _move_file(src_path, dest_path, true):
                logger.log("OVERWRITE: %s -> %s" % [src_path, dest_path])
                _after_texture_moved(src_path, dest_path)
            else:
                logger.log("ERROR: %s -> %s | Overwrite failed." % [src_path, dest_path])
        "increment":
            var final_path: String = _find_incremented_filename(dest_dir, tex_name)
            if _move_file(src_path, final_path):
                logger.log("INCREMENT: %s -> %s" % [src_path, final_path])
                _after_texture_moved(src_path, final_path)
            else:
                logger.log("ERROR: %s -> %s | Increment move failed." % [src_path, final_path])
        _:
            logger.log("WARN: Unknown collision action: %s" % action)
    call_deferred("_process_next_move")

func _move_file(src: String, dst: String, overwrite: bool = false) -> bool:
    if not FileAccess.file_exists(src):
        logger.log("ERROR: Source missing: %s" % src)
        return false
    var dst_dir: String = dst.get_base_dir()
    var mkdir_err: int = DirAccess.make_dir_recursive_absolute(dst_dir)
    if mkdir_err != OK and mkdir_err != ERR_ALREADY_EXISTS:
        logger.log("ERROR: mkdir failed: %s (err=%d)" % [dst_dir, mkdir_err])
        return false
    if FileAccess.file_exists(dst):
        if not overwrite:
            return false
        var rm_err: int = DirAccess.remove_absolute(dst)
        if rm_err != OK:
            logger.log("ERROR: remove target failed: %s (err=%d)" % [dst, rm_err])
            return false
    var copy_err: int = DirAccess.copy_absolute(src, dst)
    if copy_err == OK:
        var rm_src_err: int = DirAccess.remove_absolute(src)
        if rm_src_err == OK:
            return true
        else:
            logger.log("ERROR: Copied but rm source failed: %s (err=%d)" % [src, rm_src_err])
    else:
        logger.log("ERROR: Copy failed %s -> %s (err=%d)" % [src, dst, copy_err])
    return false

func _find_incremented_filename(dest_dir: String, base_name: String) -> String:
    var base_name_value: String = base_name.get_basename()
    var ext: String = base_name.get_extension()
    var i: int = 1
    var candidate: String = "%s%s (%d).%s" % [dest_dir, base_name_value, i, ext]
    while FileAccess.file_exists(candidate):
        i += 1
        candidate = "%s%s (%d).%s" % [dest_dir, base_name_value, i, ext]
    return candidate

# ---------------- Post-Move Processing ----------------
func _after_texture_moved(old_path: String, new_path: String) -> void:
    var modified: PackedStringArray = _patch_references(old_path, new_path)
    if not new_path in modified:
        modified.append(new_path)
    if _last_handled_glb != "" and not _last_handled_glb in modified:
        modified.append(_last_handled_glb)
    for p in modified:
        if not p in _batched_reimport:
            _batched_reimport.append(p)

# ---------------- Reference Patching ----------------
func _patch_references(old_path: String, new_path: String) -> PackedStringArray:
    _patch_cycles += 1
    if _should_rescan():
        _cached_project_files = _gather_project_files(TEXT_REFERENCE_EXTS)
        _cached_scan_generation += 1
        logger.print("File cache refreshed: %d files (generation=%d)" % [_cached_project_files.size(), _cached_scan_generation])

    var modified: PackedStringArray = []
    for f in _cached_project_files:
        # Skip if file no longer exists.
        if not FileAccess.file_exists(f):
            continue
        # Skip new path file to avoid self loops.
        if f == new_path:
            continue
        var fa_read := FileAccess.open(f, FileAccess.READ)
        if fa_read == null:
            continue
        var content: String = fa_read.get_as_text()
        fa_read.close()
        if content.find(old_path) == -1:
            continue
        var new_content: String = content.replace(old_path, new_path)
        if new_content == content:
            continue
        var fa_write := FileAccess.open(f, FileAccess.WRITE)
        if fa_write == null:
            logger.log("ERROR: Could not open for write: %s" % f)
            continue
        fa_write.store_string(new_content)
        fa_write.close()
        modified.append(f)
        logger.log("PATCH: %s -> %s in %s" % [old_path, new_path, f])

    if modified.is_empty():
        logger.print("PATCH: No references updated for %s" % old_path)
    else:
        logger.print("PATCH: %d files updated for %s" % [modified.size(), old_path])
    return modified

func _should_rescan() -> bool:
    # Rescan or if FS changed.
    var editor_fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
    var version: int = editor_fs.get_filesystem().get_modified_time()
    var fs_changed: bool = version != _last_fs_version
    if fs_changed:
        _last_fs_version = version
    return fs_changed or _cached_project_files.is_empty() or (_patch_cycles % RESCAN_INTERVAL == 0)

func _gather_project_files(extensions: PackedStringArray) -> PackedStringArray:
    var out: PackedStringArray = []
    _scan_dir_recursive("res://", extensions, out)
    return out

func _scan_dir_recursive(path: String, extensions: PackedStringArray, out: PackedStringArray) -> void:
    var dir := DirAccess.open(path)
    if dir == null:
        return
    dir.list_dir_begin()
    while true:
        var name: String = dir.get_next()
        if name == "":
            break
        if name.begins_with("."):
            continue
        var full: String = path + name
        if dir.current_is_dir():
            _scan_dir_recursive(full + "/", extensions, out)
        else:
            for ext in extensions:
                if full.ends_with(ext):
                    out.append(full)
                    break
    dir.list_dir_end()

# ---------------- Reimport Handling ----------------
func _schedule_reimport_flush() -> void:
    if _batched_reimport.is_empty():
        return
    # Delay to make sure all file writes flushed and to avoid multiple reimports reimports.
    call_deferred("_flush_reimport_batch")

func _flush_reimport_batch() -> void:
    if not Engine.is_editor_hint():
        return
    if _batched_reimport.is_empty():
        return
    var unique: PackedStringArray = []
    for p in _batched_reimport:
        if FileAccess.file_exists(p) and not p in unique:
            unique.append(p)
    _batched_reimport.clear()
    if unique.is_empty():
        return
    logger.print("REIMPORT: %d resources" % unique.size(), true)
    var editor_fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
    editor_fs.reimport_files(unique)

# ---------------- Utility ----------------
func force_full_rescan() -> void:
    _cached_project_files.clear()
    _patch_cycles = 0
    logger.print("Manual rescan requested.")
