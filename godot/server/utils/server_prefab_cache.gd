class_name ServerPrefabCache extends Node

static var headless_prefabs: Dictionary = {}

static func get_headless_prefab(original_scene: PackedScene) -> PackedScene:
	var scene_path := original_scene.resource_path

	if headless_prefabs.has(scene_path):
		return headless_prefabs[scene_path]

	var temp_instance := original_scene.instantiate()
	_strip_visuals(temp_instance)

	var headless_scene := PackedScene.new()
	var err := headless_scene.pack(temp_instance)
	if err != OK:
		push_error("ServerPrefabCache: failed to pack headless prefab for '%s' (err=%s)" % [scene_path, err])
		return original_scene

	headless_prefabs[scene_path] = headless_scene
	temp_instance.queue_free()

	return headless_scene

static func _strip_visuals(node: Node) -> void:
	for child in node.get_children():
		if child is VisualInstance3D or child is AudioStreamPlayer3D or child is GPUParticles3D:
			child.queue_free()
		else:
			_strip_visuals(child)
