extends Node

signal transition_started(from_path: String, to_path: String)
signal transition_finished(from_path: String, to_path: String)

var _is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func transition_to(path: String) -> void:
	assert(path != "", "SceneManager.transition_to(path) requires a non-empty path")
	if _is_transitioning:
		push_warning("SceneManager: transition already in progress")
		return
	_is_transitioning = true
	call_deferred("_transition_to_impl", path)

func _transition_to_impl(path: String) -> void:
	var tree := get_tree()
	assert(tree != null, "SceneManager must be inside a SceneTree")

	var from_path := ""
	if tree.current_scene != null and tree.current_scene.scene_file_path != "":
		from_path = tree.current_scene.scene_file_path

	transition_started.emit(from_path, path)
	await tree.process_frame

	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("SceneManager: failed to change scene to '%s' (err=%s)" % [path, err])

	transition_finished.emit(from_path, path)
	_is_transitioning = false
