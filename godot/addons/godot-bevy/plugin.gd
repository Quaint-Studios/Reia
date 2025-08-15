@tool
extends EditorPlugin

const WIZARD_SCENE_PATH = "res://addons/godot-bevy/wizard/project_wizard.tscn"

var wizard_dialog: Window
var _should_restart_after_build: bool = false

func _enter_tree():
	# Add menu items
	add_tool_menu_item("Setup godot-bevy Project", _on_setup_project)
	add_tool_menu_item("Add BevyApp Singleton", _on_add_singleton)
	add_tool_menu_item("Build Rust Project", _on_build_rust)

	print("godot-bevy plugin activated!")

func _exit_tree():
	# Remove menu items
	remove_tool_menu_item("Setup godot-bevy Project")
	remove_tool_menu_item("Add BevyApp Singleton")
	remove_tool_menu_item("Build Rust Project")

	if wizard_dialog:
		wizard_dialog.queue_free()

func _on_setup_project():
	# Show project wizard dialog
	if not wizard_dialog:
		var wizard_scene = load(WIZARD_SCENE_PATH)
		if wizard_scene:
			wizard_dialog = wizard_scene.instantiate()
			wizard_dialog.project_created.connect(_on_project_created)
			EditorInterface.get_base_control().add_child(wizard_dialog)
		else:
			push_error("Failed to load wizard scene")

	wizard_dialog.popup_centered(Vector2(600, 400))

func _on_add_singleton():
	var singleton_path = "res://bevy_app_singleton.tscn"

	# Always create/update the singleton scene with latest template
	_create_bevy_app_singleton(singleton_path)

	# Add to autoload (this will update if already exists) and ensure it's enabled
	ProjectSettings.set_setting("autoload/BevyAppSingleton", "*" + singleton_path)
	ProjectSettings.save()

	if ProjectSettings.has_setting("autoload/BevyAppSingleton"):
		push_warning("BevyAppSingleton updated in project autoload settings! Restart editor to apply changes.")
	else:
		push_warning("BevyAppSingleton added to project autoload settings! Restart editor to apply changes.")


func _create_bevy_app_singleton(path: String):
	# Create the scene file content with bulk transform optimization methods
	var scene_content = """[gd_scene load_steps=2 format=3 uid="uid://bjsfwt816j4tp"]

[sub_resource type="GDScript" id="GDScript_1"]
script/source = "extends BevyApp


# Bulk Transform Optimization Methods
# Automatically detected by godot-bevy library for performance optimization

func bulk_update_transforms_3d(instance_ids: PackedInt64Array, positions: PackedVector3Array, rotations: PackedVector3Array, scales: PackedVector3Array):
	for i in range(instance_ids.size()):
		var node = instance_from_id(instance_ids[i]) as Node3D
		# Trust instance IDs are valid
		node.position = positions[i]
		node.rotation = rotations[i]
		node.scale = scales[i]

func bulk_update_transforms_2d(instance_ids: PackedInt64Array, positions: PackedVector2Array, rotations: PackedFloat32Array, scales: PackedVector2Array):
	for i in range(instance_ids.size()):
		var node = instance_from_id(instance_ids[i]) as Node2D
		# Trust instance IDs are valid
		node.position = positions[i]
		node.rotation = rotations[i]
		node.scale = scales[i]
"

[node name="BevyApp" type="BevyApp"]
script = SubResource("GDScript_1")
"""

	# Save the scene file directly
	_save_file(path, scene_content)

	print("Created BevyApp singleton scene at: ", path)

func _on_project_created(project_info: Dictionary):
	# Handle the project creation based on wizard input
	_scaffold_rust_project(project_info)
	_create_bevy_app_singleton("res://bevy_app_singleton.tscn")
	_on_add_singleton()  # This will add it to autoload

	# Automatically build the Rust project and restart after
	var is_release = project_info.get("release_build", false)
	_should_restart_after_build = true
	_build_rust_project(is_release)

func _scaffold_rust_project(info: Dictionary):
	var base_path = ProjectSettings.globalize_path("res://")
	var rust_path = base_path.path_join("rust")
	var cargo_toml_path = rust_path.path_join("Cargo.toml")

	# Check if Rust project already exists
	if FileAccess.file_exists(cargo_toml_path):
		push_warning("Rust project already exists at 'rust/' directory. Skipping Rust scaffolding.")
		print("Found existing Cargo.toml at: ", cargo_toml_path)
		return

	# Debug: Print the info dictionary
	print("Project info received: ", info)
	print("Project name value: '", info.get("project_name", "KEY_NOT_FOUND"), "'")

	# Validate project name
	var project_name = info.project_name.strip_edges()
	if project_name.is_empty():
		project_name = "my_game"
		push_warning("Empty project name, using default: my_game")

	# Create directory structure
	DirAccess.make_dir_recursive_absolute(rust_path.path_join("src"))

	# Create Cargo.toml
	var cargo_content = """[package]
name = "%s"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
bevy = { version = "0.16", default-features = false, features = ["bevy_state"] }
godot = "0.3"
godot-bevy = "%s"

[workspace]
# Empty workspace table to make this a standalone project
""" % [_to_snake_case(project_name), info.godot_bevy_version]

	if info.use_defaults:
		cargo_content = cargo_content.replace('godot-bevy = "%s"' % info.godot_bevy_version,
			'godot-bevy = { version = "%s", features = ["default"] }' % info.godot_bevy_version)

	_save_file(rust_path.path_join("Cargo.toml"), cargo_content)

	# Always use GodotDefaultPlugins for bootstrapping
	# Users can customize plugin selection in their generated code
	var plugin_config = "app.add_plugins(GodotDefaultPlugins);"

	# Create lib.rs
	var lib_content = """use godot::prelude::*;
use bevy::prelude::*;
use godot_bevy::prelude::*;

#[bevy_app]
fn build_app(app: &mut App) {
	// GodotDefaultPlugins provides all standard godot-bevy functionality
	// For minimal setup, use individual plugins instead:
	// app.add_plugins(GodotTransformSyncPlugin)
	//     .add_plugins(GodotAudioPlugin)
	//     .add_plugins(BevyInputBridgePlugin);
	%s

	// Add your systems here
	app.add_systems(Update, hello_world_system);
}

fn hello_world_system(mut timer: Local<f32>, time: Res<Time>) {
	// This runs every frame in Bevy's Update schedule
	*timer += time.delta_secs();
	if *timer > 1.0 {
		*timer = 0.0;
		godot_print!("Hello from Bevy ECS!");
	}
}
""" % [plugin_config]

	_save_file(rust_path.path_join("src/lib.rs"), lib_content)

	# Create .gdextension file
	var gdextension_content = """[configuration]
entry_symbol = "gdext_rust_init"
compatibility_minimum = 4.1

[libraries]
linux.debug.x86_64 = "res://rust/target/debug/lib%s.so"
linux.release.x86_64 = "res://rust/target/release/lib%s.so"
windows.debug.x86_64 = "res://rust/target/debug/%s.dll"
windows.release.x86_64 = "res://rust/target/release/%s.dll"
macos.debug = "res://rust/target/debug/lib%s.dylib"
macos.release = "res://rust/target/release/lib%s.dylib"
macos.debug.arm64 = "res://rust/target/debug/lib%s.dylib"
macos.release.arm64 = "res://rust/target/release/lib%s.dylib"
""" % [
		_to_snake_case(project_name),
		_to_snake_case(project_name),
		_to_snake_case(project_name),
		_to_snake_case(project_name),
		_to_snake_case(project_name),
		_to_snake_case(project_name),
		_to_snake_case(project_name),
		_to_snake_case(project_name)
	]

	_save_file(base_path.path_join("rust.gdextension"), gdextension_content)

	push_warning("Rust project scaffolded successfully! Building now...")

func _on_build_rust():
	# Build the Rust project (called from menu)
	_should_restart_after_build = false  # Don't restart for manual builds
	_build_rust_project(false)  # Default to debug build

func _build_rust_project(release_build: bool):
	var base_path = ProjectSettings.globalize_path("res://")
	var rust_path = base_path.path_join("rust")

	# Check if rust directory exists
	if not DirAccess.dir_exists_absolute(rust_path):
		push_error("No Rust project found! Run 'Setup godot-bevy Project' first.")
		return

	# Prepare cargo command with working directory
	var args = ["build", "--manifest-path", rust_path.path_join("Cargo.toml")]
	if release_build:
		args.append("--release")

	print("Building Rust project...")
	print("Running: cargo ", " ".join(args))

	# Execute cargo build
	var output = []
	var exit_code = OS.execute("cargo", args, output, true, true)

	# Process results
	if exit_code == 0:
		var build_type = "debug" if not release_build else "release"
		push_warning("Rust build completed successfully! (%s)" % build_type)
		print("Build output:")
		for line in output:
			print("  ", line)

		# Restart editor if this was called from project setup
		if _should_restart_after_build:
			push_warning("Restarting editor to apply autoload changes...")
			EditorInterface.restart_editor()
	else:
		push_error("Rust build failed with exit code: %d" % exit_code)
		print("Build errors:")
		for line in output:
			print("  ", line)

func _save_file(path: String, content: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("Created: ", path)
	else:
		push_error("Failed to create file: " + path)

# Helper functions for case conversion
func _to_snake_case(text: String) -> String:
	var result = ""
	for i in range(text.length()):
		var c = text[i]
		# Check if character is uppercase by comparing with lowercase version
		if c != c.to_lower() and i > 0:
			result += "_"
		result += c.to_lower()
	return result

func _to_pascal_case(text: String) -> String:
	var words = text.split("_")
	var result = ""
	for word in words:
		if word.length() > 0:
			result += word[0].to_upper() + word.substr(1).to_lower()
	return result
