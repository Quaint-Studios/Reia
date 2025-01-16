@tool
class_name GameManager__Plugin extends EditorPlugin

const PLUGIN_NAME := "Game Manager"
const PLUGIN_FOLDER := "game_manager"

# const CoreScene : PackedScene = preload('res://addons/game_manager/components/core/core.tscn')

var core_instance: GameManager__Core

func _enter_tree() -> void:
	core_instance = (load('res://addons/game_manager/components/core/core.tscn') as PackedScene).instantiate() as GameManager__Core

	# Setup
	core_instance.undo_redo = get_undo_redo()
	var __ := core_instance.reload_plugin.connect(reload_plugin)

	# add core_instance to main viewport
	EditorInterface.get_editor_main_screen().add_child(core_instance)

	_make_visible(false)

	print_debug('%s Enabled' % PLUGIN_NAME)

func _get_plugin_name() -> String:
	return PLUGIN_NAME

func _get_plugin_icon() -> Texture2D:
	return preload("res://addons/game_manager/icons/game_manager_icon.svg")

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if is_instance_valid(core_instance):
		core_instance.visible = visible

func _exit_tree() -> void:
		# remove from main viewport
	if is_instance_valid(core_instance):
		core_instance.queue_free()

	print_debug('%s Disabled' % PLUGIN_NAME)

func reload_plugin() -> void:
	print("Reloading the %s plugin..." % PLUGIN_NAME)
	EditorInterface.call_deferred("set_plugin_enabled", PLUGIN_FOLDER, false)
	EditorInterface.call_deferred("set_plugin_enabled", PLUGIN_FOLDER, true)
