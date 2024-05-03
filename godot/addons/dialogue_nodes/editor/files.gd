@tool
extends ItemList


signal file_list_changed
signal file_switched

@export var editor_path : NodePath
@export var workspace_path : NodePath
@export var data_path : NodePath

@onready var popup_menu = $PopupMenu
@onready var new_dialog = $NewDialog
@onready var save_as_dialog = $SaveDialog
@onready var open_dialog = $OpenDialog
@onready var confirm_dialog = $ConfirmationDialog

const VariablesScene = preload("res://addons/dialogue_nodes/editor/Variables.tscn")
const GraphScene = preload("res://addons/dialogue_nodes/editor/Graph.tscn")

var editor
var workspace
var data_container
var file_icon := preload('res://addons/dialogue_nodes/icons/Script.svg')
var cur_idx := -1
var deletion_queue := []


func _ready():
	editor = get_node(editor_path)
	workspace = get_node(workspace_path)
	data_container = get_node(data_path)
	
	confirm_dialog.get_ok_button().hide()
	confirm_dialog.add_button('Save', true, 'save_file')
	confirm_dialog.add_button('Discard', true, 'discard_file')
	confirm_dialog.add_cancel_button('Cancel')
	
	data_container.get_node('Characters').modified.connect(_on_data_modified)


func create_entry(file_name : String, path : String, data : DialogueData):
	var new_idx : int = item_count
	
	# check if the file is already loaded
	var already_loaded : = false
	for idx in range(item_count):
		if get_item_metadata(idx)['path'] == path:
			new_idx = idx
			already_loaded = true
	
	if not already_loaded:
		var metadata = {
			'display_name': file_name,
			'path': path,
			'characters': data.characters,
			'variables': null,
			'graph': null,
			'modified': false
			}
		
		# create graph node for this file
		var graph = GraphScene.instantiate()
		add_child(graph)
		graph.undo_redo = editor.undo_redo
		graph.modified.connect(_on_data_modified)
		graph.load_data(data)
		remove_child(graph)
		metadata['graph'] = graph
		
		# create variables node for this file
		var variables = VariablesScene.instantiate()
		add_child(variables)
		variables.undo_redo = editor.undo_redo
		variables.modified.connect(_on_data_modified)
		variables.load_data(data.variables)
		remove_child(variables)
		metadata['variables'] = variables
	
		# add new item and set metadata
		add_item(file_name, file_icon)
		set_item_metadata(new_idx, metadata)
	
		# change if the file name is already in use
		for idx in range(item_count):
			if idx != new_idx and get_item_text(idx) == file_name:
				show_dir(idx)
				show_dir(new_idx)
	
	if cur_idx == -1:
		switch_file(new_idx)
	else:
		_on_file_selected(new_idx)
	
	data_container.show()
	file_list_changed.emit()


func show_dir(idx: int):
	var metadata = get_item_metadata(idx)
	var parts = metadata['path'].split('/')
	if parts[-2] != '':
		var display_name = parts[-2] + '/' + parts[-1]
		metadata['display_name'] = display_name
		set_item_text(idx, display_name)
		set_item_metadata(idx, metadata)


func new_file(path: String):
	var file_name : String = path.split('/')[-1]
	var data = DialogueData.new()
	
	# create entry for file
	create_entry(file_name, path, data)
	
	# save dialogue data to file
	ResourceSaver.save(data, path)
	
	if editor._debug:
		print('File created: ', path)


func open_file(path: String):
	var file_name : String = path.split('/')[-1]
	var data = ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE)
	if not data is DialogueData:
		printerr('File is not supported!')
		return
	
	# create entry for file
	create_entry(file_name, path, data)
	
	if editor._debug:
		print('File opened: ', path)


func save_file(idx := cur_idx):
	if idx < 0: return
	
	var metadata = get_item_metadata(idx)
	
	var data : DialogueData = metadata['graph'].get_data()
	if idx == cur_idx:
		data.characters = data_container.get_node('Characters').get_data()
	else:
		data.characters = metadata['characters']
	data.variables = metadata['variables'].get_data()
	
	# save to file
	ResourceSaver.save(data, metadata['path'])
	set_item_metadata(idx, metadata)
	
	# toggle modified flag
	set_modified(idx, false)
	
	# load new resource so Godot knows to replace it
	var _data = ResourceLoader.load(metadata['path'], '', ResourceLoader.CACHE_MODE_REPLACE)
	
	if editor._debug:
		print('File saved: ', metadata['path'])


func save_as(path : String):
	var file_name : String = path.split('/')[-1]
	var metadata = get_item_metadata(cur_idx)
	
	var data : DialogueData = metadata['graph'].get_data()
	data.characters = data_container.get_node('Characters').get_data()
	data.variables = metadata['variables'].get_data()
	
	# create entry for file
	create_entry(file_name, path, data)
	
	# save dialogue data to file
	ResourceSaver.save(data, path)
	
	if editor._debug:
		print('File saved as: ', path)


func save_all():
	for idx in range(item_count):
		save_file(idx)


func close_file(idx := cur_idx):
	if item_count == 0: return
	
	idx = wrapi(idx, 0, item_count)
	var metadata = get_item_metadata(idx)

	if metadata['modified'] and not idx in deletion_queue:
		deletion_queue.append(idx)
		confirm_dialog.popup_centered()
		return
	
	if idx == cur_idx:
		if item_count == 1:
			cur_idx = -1
		elif idx == 0:
			switch_file(1)
			cur_idx = 0
		else:
			switch_file(idx - 1)
	
	if workspace == metadata['graph'].get_parent():
		workspace.remove_child(metadata['graph'])
		metadata['graph'].queue_free()
	if data_container == metadata['variables'].get_parent():
		data_container.remove_child(metadata['variables'])
		metadata['variables'].queue_free()
	remove_item(idx)
	
	if item_count == 0: data_container.hide()
	
	file_list_changed.emit()
	
	if editor._debug:
		print('File closed: ', metadata['path'])


func close_all():
	# check any modified files
	deletion_queue.clear()
	for idx in range(item_count):
		if get_item_metadata(idx)['modified']:
			deletion_queue.append(idx)
	if deletion_queue.size() > 0:
		confirm_dialog.popup_centered()
		return
	
	# delete if none are modified
	cur_idx = -1 
	for idx in range(item_count):
		close_file(0)


func switch_file(idx : int, ensure_path := ''):
	if item_count == 0 or idx > item_count:
		return
	
	idx = wrapi(idx, 0, item_count)
	var new_metadata = get_item_metadata(idx)
	
	# ensure the path is the same
	if ensure_path != '' and new_metadata['path'] != ensure_path:
		return
	
	# remove previous nodes if any and update character metadata
	if cur_idx > -1:
		var cur_metadata = get_item_metadata(cur_idx)
		if workspace.has_node('Graph'):
			editor.add_menu.get_popup().id_pressed.disconnect(cur_metadata['graph']._on_add_menu_pressed)
			data_container.get_node('Characters').characters_updated.disconnect(cur_metadata['graph']._on_characters_updated)
			workspace.remove_child(cur_metadata['graph'])
		if data_container.has_node('Variables'):
			data_container.remove_child(cur_metadata['variables'])
		cur_metadata['characters'] = data_container.get_node('Characters').get_data()
		set_item_metadata(cur_idx, cur_metadata)
	
	# add new nodes
	data_container.get_node('Characters').characters_updated.connect(new_metadata['graph']._on_characters_updated)
	workspace.add_child(new_metadata['graph'])
	data_container.get_node('Characters').load_data(new_metadata['characters'])
	editor.add_menu.get_popup().id_pressed.connect(new_metadata['graph']._on_add_menu_pressed)
	data_container.add_child(new_metadata['variables'])
	
	cur_idx = idx
	select(idx)
	
	file_switched.emit()


func set_modified(idx : int, value : bool):
	if cur_idx == -1:
		return
	
	var metadata = get_item_metadata(idx)
	metadata['modified'] = value
	set_item_metadata(idx, metadata)
	var suffix = '(*)' if value else ''
	set_item_text(idx, metadata['display_name'] + suffix)


func get_current_metadata():
	if cur_idx == -1: return {}
	
	return get_item_metadata(cur_idx)


func _on_empty_clicked(at_pos : Vector2, mouse_button_index : int):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var pop_pos = at_pos + global_position + Vector2(get_window().position)
		popup_menu.popup(Rect2(pop_pos, popup_menu.size))


func _on_item_clicked(_idx, at_pos : Vector2, mouse_button_index : int):
	_on_empty_clicked(at_pos, mouse_button_index)


func _on_toolbar_menu_pressed(id : int):
	
	match( id ):
		0:
			# new file
			new_dialog.popup_centered()
		1:
			# open file
			open_dialog.popup_centered()
		2:
			# save file
			save_file()
		3:
			# save as
			if item_count > 0:
				save_as_dialog.popup_centered()
		4:
			# close file
			close_file()
		5:
			# close all
			close_all()


func _on_popup_menu_pressed(id : int):
	match (id):
		0:
			# save
			save_file()
		1:
			# save as
			if item_count > 0:
				save_as_dialog.popup_centered()
		2:
			# close
			close_file()
		3:
			# close all
			close_all()


func _on_file_selected(idx : int):
	if not editor.undo_redo:
		switch_file(idx)
		return
	
	var cur_metadata = get_item_metadata(cur_idx)
	var new_metadata = get_item_metadata(idx)
	
	editor.undo_redo.create_action('Switch file')
	editor.undo_redo.add_do_method(self, 'switch_file', idx, new_metadata['path'])
	editor.undo_redo.add_undo_method(self, 'switch_file', cur_idx, cur_metadata['path'])
	editor.undo_redo.commit_action()


func _on_data_modified(_a=0):
	set_modified(cur_idx, true)


func _on_confirm_dialog_action(action : String):
	confirm_dialog.hide()
	
	if deletion_queue.size() == 0:
		return
	
	match (action):
		'save_file':
			for idx in deletion_queue:
				save_file(idx)
			close_all()
				#await get_tree().idle_frame
		'discard_file':
			for idx in range(item_count):
				close_file(-1)
	deletion_queue.clear()


func _on_confirm_dialog_canceled():
	deletion_queue.clear()
