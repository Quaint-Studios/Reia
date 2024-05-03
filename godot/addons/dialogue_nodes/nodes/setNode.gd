@tool
extends GraphNode


signal modified

@onready var variable = $BoxContainer/Variable
@onready var variable_timer = $VariableTimer
@onready var type = $BoxContainer/Type
@onready var value = $BoxContainer/Value
@onready var value_timer = $ValueTimer

var undo_redo : EditorUndoRedoManager
var last_variable : String
var last_type : int
var last_value : String


func _to_dict(graph : GraphEdit):
	var dict = {}
	var connections = graph.get_connections(name)
	
	dict['variable'] = variable.text
	dict['type'] = type.selected
	dict['value'] = value.text
	dict['link'] = connections[0]['to_node'] if connections.size() > 0 else 'END'
	
	return dict


func _from_dict(dict : Dictionary):
	variable.text = dict['variable']
	type.selected = dict['type']
	value.text = dict['value']
	
	last_variable = variable.text
	last_type = type.selected
	last_value = value.text
	
	return [dict['link']]


func set_variable(new_variable : String):
	if variable.text != new_variable:
		variable.text = new_variable
	last_variable = new_variable


func set_value(new_value : String):
	if value.text != new_value:
		value.text = new_value
	last_value = new_value


func _on_variable_changed(_new_text):
	variable_timer.stop()
	variable_timer.start()


func _on_variable_timer_timeout():
	if not undo_redo: return
	
	undo_redo.create_action('Set variable name')
	undo_redo.add_do_method(self, 'set_variable', variable.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_variable', last_variable)
	undo_redo.commit_action()


func _on_type_selected(idx : int):
	if not undo_redo: return
	
	undo_redo.create_action('Set operator type')
	undo_redo.add_do_method(type, 'select', idx)
	undo_redo.add_do_property(self, 'last_type', idx)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(type, 'select', last_type)
	undo_redo.add_undo_property(self, 'last_type', last_type)
	undo_redo.commit_action()


func _on_value_changed(_new_text):
	value_timer.stop()
	value_timer.start()


func _on_value_timer_timeout():
	if not undo_redo: return
	
	undo_redo.create_action('Set value')
	undo_redo.add_do_method(self, 'set_value', value.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_value', last_value)
	undo_redo.commit_action()


func _on_modified():
	modified.emit()
