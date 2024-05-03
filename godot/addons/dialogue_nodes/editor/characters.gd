@tool
extends Control


signal modified
signal characters_updated(character_list : Array[Character])

@export var editor_path: NodePath

@onready var reset_button = $HBoxContainer/ResetButton
@onready var file_path = $HBoxContainer/FilePath
@onready var load_button = $HBoxContainer/LoadButton
@onready var open_dialog = $OpenDialog

var editor
var last_file_path : String


func _ready():
	editor = get_node(editor_path)
	reset_button.hide()


func get_data():
	return file_path.text


func load_data(path : String):
	if path == '':
		reset_button.hide()
	else:
		reset_button.show()
	
	if path != file_path.text:
		file_path.text = path
	last_file_path = path
	
	var resource : Resource
	var character_list : Array[Character] = []
	if path.ends_with('.tres') and ResourceLoader.exists(path):
		resource = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_REPLACE)
		if resource is CharacterList:
			character_list = resource.characters
	
	characters_updated.emit(character_list)
	
	if editor._debug:
		print('Character data set: ', path)
		if path.ends_with('.tres'):
			if resource is CharacterList:
				print('Loaded characters:', resource.characters)
			else:
				printerr('Selected file is not a CharacterList resource')


func _on_reset_button_pressed():
	if not editor.undo_redo:
		load_data('')
		return
	
	var cur_path = file_path.text
	editor.undo_redo.create_action('Reset character list path')
	editor.undo_redo.add_do_method(self, 'load_data', '')
	editor.undo_redo.add_do_method(self, '_on_modified')
	editor.undo_redo.add_undo_method(self, '_on_modified')
	editor.undo_redo.add_undo_method(self, 'load_data', cur_path)
	editor.undo_redo.commit_action()


func _on_file_path_text_changed():
	if not editor.undo_redo:
		load_data(file_path.text)
		return
	
	editor.undo_redo.create_action('Set character list path')
	editor.undo_redo.add_do_method(self, 'load_data', file_path.text)
	editor.undo_redo.add_do_method(self, '_on_modified')
	editor.undo_redo.add_undo_method(self, '_on_modified')
	editor.undo_redo.add_undo_method(self, 'load_data', last_file_path)
	editor.undo_redo.commit_action()


func _on_load_button_pressed():
	open_dialog.popup_centered()


func _on_file_selected(path : String):
	if not editor.undo_redo:
		load_data(path)
		return
	
	editor.undo_redo.create_action('Set character list path')
	editor.undo_redo.add_do_method(self, 'load_data', path)
	editor.undo_redo.add_do_method(self, '_on_modified')
	editor.undo_redo.add_undo_method(self, '_on_modified')
	editor.undo_redo.add_undo_method(self, 'load_data', file_path.text)
	editor.undo_redo.commit_action()


func _on_modified():
	modified.emit()
