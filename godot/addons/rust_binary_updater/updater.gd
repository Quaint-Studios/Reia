@tool
extends EditorPlugin

const R2_BASE_URL = "https://rust.r2.playreia.com/latest/"
const MANIFEST_URL = R2_BASE_URL + "manifest.json"
const LOCAL_MANIFEST_PATH = "res://build/bin/manifest.json"
const BIN_DIR = "res://build/bin/"

var http_request: HTTPRequest
var _pending_downloads: int = 0
var _failed_replacements: Array = []
var _current_manifest: Dictionary = {}
var _reia_tools_menu: PopupMenu
var _force_next_update: bool = false

func _enter_tree():
	# Ensure the bin directory exists
	if not DirAccess.dir_exists_absolute(BIN_DIR):
		DirAccess.make_dir_absolute(BIN_DIR)

	# Setup the custom context menu under Project -> Tools
	_setup_menu()

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_manifest_downloaded)

	_check_for_updates_on_startup()

func _exit_tree():
	if http_request:
		http_request.queue_free()

	remove_tool_menu_item("Reia Tools")
	if _reia_tools_menu:
		_reia_tools_menu.queue_free()

func _setup_menu():
	_reia_tools_menu = PopupMenu.new()
	_reia_tools_menu.add_item("Update Rust Binaries", 0)
	_reia_tools_menu.add_item("Finalize Rust Binary Update", 1)
	_reia_tools_menu.id_pressed.connect(_on_reia_tools_menu_pressed)
	add_tool_submenu_item("Reia Tools", _reia_tools_menu)

func _on_reia_tools_menu_pressed(id: int):
	if id == 0:
		print("[RustUpdater] Manual update triggered. Fetching remote manifest...")
		_force_next_update = true
		_fetch_remote_manifest()
	elif id == 1:
		_attempt_manual_finalize()

func _check_for_updates_on_startup():
	var local_manifest := _get_local_manifest()
	var local_manifest_hash := local_manifest.get("commit_hash", "")

	# Attempt to get the current Git hash
	var output := []
	var exit_code := OS.execute("git", ["rev-parse", "HEAD"], output, true, true)

	if exit_code == 0 and output.size() > 0:
		var current_git_hash: String = output[0].strip_edges()

		if local_manifest_hash != "" and current_git_hash == local_manifest_hash:
			print("[RustUpdater] Git hash matches local manifest (", current_git_hash.substr(0, 7), "). Rust binaries are up to date.")
			return # Skip the HTTP request entirely!
		else:
			print("[RustUpdater] Git commit changed or missing local manifest. Fetching remote manifest to check for updates...")
			_fetch_remote_manifest()
	else:
		print("[RustUpdater] No Git repository detected (or Git not installed). Checking remote manifest on startup to ensure binaries are up to date.")
		_fetch_remote_manifest()

func _fetch_remote_manifest():
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request.cancel_request()
	http_request.request(MANIFEST_URL)

func _on_manifest_downloaded(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200:
		push_error("[RustUpdater] Failed to fetch manifest. Network error or R2 bucket not public. Code: " + str(response_code))
		return

	var json := JSON.new()
	var error := json.parse(body.get_string_from_utf8())
	if error == OK:
		var remote_manifest := json.data
		_compare_and_update(remote_manifest)
	else:
		push_error("[RustUpdater] Failed to parse remote manifest JSON.")

func _compare_and_update(remote_manifest: Dictionary):
	var local_manifest := _get_local_manifest()

	var remote_hash := remote_manifest.get("commit_hash", "")
	var local_hash := local_manifest.get("commit_hash", "")

	if _force_next_update or local_manifest.is_empty() or local_hash != remote_hash:
		_force_next_update = false
		print("[RustUpdater] New version required! (Remote Hash: ", remote_hash.substr(0, 7), "). Preparing download...")
		_download_binary(remote_manifest)
	else:
		_force_next_update = false
		print("[RustUpdater] Rust binaries are already up to date.")

func _get_local_manifest() -> Dictionary:
	if not FileAccess.file_exists(LOCAL_MANIFEST_PATH):
		return {}
	var file := FileAccess.open(LOCAL_MANIFEST_PATH, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err == OK:
		return json.data
	return {}

func _download_binary(manifest: Dictionary):
	var os_name := OS.get_name()
	var target_os := "Linux"
	if os_name == "Windows":
		target_os = "Windows"
	elif os_name == "macOS":
		target_os = "macOS"

	var bin_info: Dictionary = manifest.get("binaries", {}).get(target_os, {})

	if bin_info.is_empty():
		push_error("[RustUpdater] Missing binary in remote manifest for OS: " + target_os + " (Detected: " + os_name + ")")
		return

	_current_manifest = manifest
	_pending_downloads = 0
	_failed_replacements.clear()

	# Loop through both debug and release configurations
	for build_type in ["debug", "release"]:
		var build_data: Dictionary = bin_info.get(build_type, {})
		if not build_data.is_empty():
			var expected_hash: String = build_data.get("sha256", "")
			_start_download(build_data["file"], build_type, target_os, expected_hash)

func _start_download(file_path: String, build_type: String, target_os: String, expected_hash: String):
	var final_filename := file_path
	var download_path := BIN_DIR + final_filename + ".update"
	var final_path := BIN_DIR + final_filename
	var file_url := R2_BASE_URL + file_path

	var file_http := HTTPRequest.new()
	add_child(file_http)
	file_http.download_file = download_path

	_pending_downloads += 1

	# Pass the expected_hash through
	file_http.request_completed.connect(func(res, code, hdrs, bdy):
		_on_binary_downloaded(res, code, download_path, final_path, expected_hash, file_http)
	)
	
	print("[RustUpdater] Downloading ", build_type, " build -> ", download_path)
	file_http.request(file_url)

func _apply_macos_fixes(path: String):
	if OS.get_name() != "macOS":
		return

	var global_path = ProjectSettings.globalize_path(path)

	# 1. Clear quarantine attributes (removes the "Downloaded from Internet" warning)
	# -c clears all extended attributes
	OS.execute("xattr", ["-c", global_path], [])

	# 2. Ad-hoc sign the binary (required for Apple Silicon execution)
	OS.execute("codesign", ["--force", "-s", "-", global_path], [])

	print("[RustUpdater] Applied macOS security fixes to: ", path.get_file())


func _on_binary_downloaded(result: int, response_code: int, downloaded_path: String, final_path: String, expected_hash: String, http_node: HTTPRequest):
	http_node.queue_free()
	_pending_downloads -= 1

	if response_code == 200:
		var final_name: String = final_path.get_file()

		# Verify the file integrity
		var actual_hash := FileAccess.get_sha256(downloaded_path)
		if expected_hash != "" and actual_hash != expected_hash:
			push_error("[RustUpdater] HASH MISMATCH for " + final_name + "! File corrupted during download.")
			push_error("Expected: " + expected_hash + " | Got: " + actual_hash)
			DirAccess.remove_absolute(downloaded_path) # Delete the bad file
			_failed_replacements.append(final_name)
		else:
			# Proceed with hot-swap if verified
			var err := OK
			if FileAccess.file_exists(final_path):
				err = DirAccess.remove_absolute(final_path)
				
			if err == OK:
				err = DirAccess.rename_absolute(downloaded_path, final_path)
				if err == OK:
					if OS.get_name() == "macOS" or OS.get_name() == "Linux":
						OS.execute("chmod", ["+x", ProjectSettings.globalize_path(final_path)], [])
					
					_apply_macos_fixes(final_path)

					print("[RustUpdater] Successfully verified and hot-swapped: ", final_name)
				else:
					_failed_replacements.append(final_name)
			else:
				_failed_replacements.append(final_name)
	else:
		push_error("[RustUpdater] Failed to download binary. Code: " + str(response_code))
		
	if _pending_downloads == 0:
		_finalize_update()

func _finalize_update():
	var file := FileAccess.open(LOCAL_MANIFEST_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(_current_manifest, "\t"))

	if _failed_replacements.size() > 0:
		push_warning("==================================================")
		push_warning("[RustUpdater] UPDATE DOWNLOADED, BUT FILES ARE LOCKED OR CORRUPTED!")
		push_warning("Could not automatically replace: " + str(_failed_replacements))
		push_warning("Because active binaries are locked, try these steps:")
		push_warning("1. Stop the project if it is currently playing/running.")
		push_warning("2. Go to Project -> Tools -> Reia Tools -> Finalize Rust Binary Update")
		push_warning("=================== EXTRA HELP ===================")
		push_warning("3. If that doesn't work, close the Godot Editor entirely.")
		push_warning("4. Manually delete the old binaries in res://build/bin/ and rename the .update files to their correct names (remove the .update suffix).")
		push_warning("5. Reopen the project.")
		push_warning("==================================================")
	else:
		push_warning("==================================================")
		push_warning("[RustUpdater] ALL UPDATES VERIFIED AND APPLIED SUCCESSFULLY!")
		push_warning("The new GDExtension binaries are in place.")
		push_warning("Godot should reload them automatically.")
		push_warning("==================================================")

func _attempt_manual_finalize():
	print("[RustUpdater] Attempting to finalize locked updates...")
	var dir := DirAccess.open(BIN_DIR)
	if not dir:
		push_error("[RustUpdater] Could not open bin directory.")
		return

	var found_updates := false
	var still_locked := []

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".update"):
			found_updates = true
			var update_path := BIN_DIR + file_name
			var target_path := BIN_DIR + file_name.trim_suffix(".update")
			
			var err := OK
			if FileAccess.file_exists(target_path):
				err = DirAccess.remove_absolute(target_path)
				
			if err == OK:
				err = DirAccess.rename_absolute(update_path, target_path)
				if err == OK:
					if OS.get_name() == "macOS" or OS.get_name() == "Linux":
						OS.execute("chmod", ["+x", ProjectSettings.globalize_path(target_path)], [])
					
					_apply_macos_fixes(target_path)
					print("[RustUpdater] Successfully replaced: ", target_path.get_file())
				else:
					still_locked.append(target_path.get_file())
			else:
				still_locked.append(target_path.get_file())
		file_name = dir.get_next()
		
	if not found_updates:
		print("[RustUpdater] No pending .update files found.")
	elif still_locked.size() > 0:
		push_error("[RustUpdater] Some files are still locked: " + str(still_locked) + ". Please close the editor and manually apply.")
	else:
		push_warning("[RustUpdater] Manual finalization successful! Godot should reload the binaries now.")
