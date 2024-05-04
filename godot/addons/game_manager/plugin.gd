@tool
extends EditorPlugin

# const CoreScene : PackedScene = preload('res://addons/game_manager/components/core/core.tscn')

var core_instance: GameManager__Core

func _enter_tree() -> void:
	core_instance = (load('res://addons/game_manager/components/core/core.tscn') as PackedScene).instantiate() as GameManager__Core # CoreScene.instantiate()

	# add core_instance to main viewport
	get_editor_interface().get_editor_main_screen().add_child(core_instance)

	core_instance.undo_redo = get_undo_redo()

	_make_visible(false)

	print_debug('Game Manager Enabled')

func _get_plugin_name() -> String:
	return "Game Manager"

func _get_plugin_icon() -> Texture2D:
	return preload("res://addons/game_manager/icons/game_manager_icon.svg")

func _has_main_screen():
	return true

func _make_visible(visible: bool) -> void:
	if is_instance_valid(core_instance):
		core_instance.visible = visible

func _exit_tree() -> void:
		# remove from main viewport
	if is_instance_valid(core_instance):
		core_instance.queue_free()

	print_debug('Game Manager Disabled')
