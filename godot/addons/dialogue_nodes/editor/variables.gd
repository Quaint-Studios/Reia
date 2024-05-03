@tool
extends Control


signal modified

@onready var var_container = $ScrollContainer/VBoxContainer

var undo_redo : EditorUndoRedoManager
var variable_item_scene = preload('res://addons/dialogue_nodes/editor/VariableItem.tscn')


func get_data() -> Dictionary:
	var dict := {}
	
	for child in var_container.get_children():
		if child is HBoxContainer:
			var var_name = child.get_var_name()
			if var_name != '':
				dict[var_name] = child.get_data()
	
	return dict


func load_data(dict: Dictionary):
	# remove old variables
	clear()
	
	# add values
	for var_name in dict:
		add_variable(var_name, dict[var_name], -1, true)


## add new variable item to the list
func add_variable(new_name= '', data= {'type': TYPE_STRING, 'value': ''}, to_idx= -1, skip_signal= false):
	var new_variable = variable_item_scene.instantiate()
	var_container.add_child(new_variable, true)
	
	if to_idx > -1:
		var_container.move_child(new_variable, to_idx)
	
	new_variable.load_data(new_name, data)
	new_variable.undo_redo = undo_redo
	new_variable.modified.connect(_on_modified)
	new_variable.delete_requested.connect(_on_delete_requested)
	
	if not skip_signal:
		_on_modified()
	
	return new_variable


## remove the variable with at the given index (idx)
func remove_variable(idx: int):
	var variable = var_container.get_child(idx)
	variable.queue_free()
	_on_modified()


## clear variable list
func clear():
	for child in var_container.get_children():
		if child is HBoxContainer:
			child.queue_free()


func get_variable(var_name):
	for child in var_container.get_children():
		if child is HBoxContainer and child.get_var_name() == var_name:
			return child
	
	printerr('Variable not found : ', var_name)
	return null


func get_value(var_name):
	return get_variable(var_name).get_value()


func set_value(var_name, value):
	if var_name == '':
		return
	get_variable(var_name).set_value(value)


func _on_add_button_pressed():
	if not undo_redo:
		add_variable()
		return
	
	undo_redo.create_action('Create variable')
	undo_redo.add_do_method(self, 'add_variable')
	undo_redo.add_undo_method(self, 'remove_variable', -1)
	undo_redo.commit_action()


func _on_delete_requested(variable: HBoxContainer):
	if not undo_redo:
		variable.queue_free()
		return
	
	var idx = variable.get_index()
	undo_redo.create_action('Delete variable')
	undo_redo.add_do_method(var_container, 'remove_child', variable)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(var_container, 'add_child', variable)
	undo_redo.add_undo_method(var_container, 'move_child', variable, idx)
	undo_redo.add_undo_reference(variable)
	undo_redo.commit_action()


func _on_modified(_a= 0, _b= 0):
	modified.emit()
