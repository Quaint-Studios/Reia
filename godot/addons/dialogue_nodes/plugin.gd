@tool
extends EditorPlugin


const EditorScene = preload('res://addons/dialogue_nodes/Editor.tscn')
const DialogueBoxScene = preload('res://addons/dialogue_nodes/objects/dialogueBox.gd')
const DialogueBoxIcon = preload('res://addons/dialogue_nodes/icons/Dialogue.svg')

var editor


func _enter_tree():
	editor = EditorScene.instantiate()
	
	# add editor to main viewport
	get_editor_interface().get_editor_main_screen().add_child(editor)
	
	# get undo redo manager
	editor.undo_redo = get_undo_redo()
	
	_make_visible(false)
	
	# add dialogue provider node
	add_custom_type(
		'DialogueBox',
		'Panel',
		DialogueBoxScene,
		DialogueBoxIcon)
	
	print_debug('Plugin Enabled')


func _exit_tree():
	# remove from main viewport
	if is_instance_valid(editor):
		editor.queue_free()
	
	remove_custom_type('DialogueBox')
	
	print_debug('Plugin Disabled')


func _has_main_screen():
	return true


func _make_visible(visible):
	if is_instance_valid(editor):
		editor.visible = visible


func _get_plugin_name():
	return 'Dialogue'


func _get_plugin_icon():
	return preload('res://addons/dialogue_nodes/icons/Dialogue.svg')


func _handles(object):
	return object is DialogueData


func _edit(object):
	if object is DialogueData and is_instance_valid(editor):
		editor.files.open_file(object.resource_path)


func _save_external_data():
	if is_instance_valid(editor):
		editor.files.save_all()
