@tool
extends GraphNode


signal modified

@onready var value1 = $BoxContainer/Value1
@onready var value1_timer = $Value1Timer
@onready var operator = $BoxContainer/Operator
@onready var value2 = $BoxContainer/Value2
@onready var value2_timer = $Value2Timer

var undo_redo : EditorUndoRedoManager
var last_operator : int


func _ready():
	value1.set_meta('last_value', value1.text)
	value2.set_meta('last_value', value2.text)


func _to_dict(graph : GraphEdit):
	var dict = {}
	dict['value1'] = value1.text
	dict['operator'] = operator.selected
	dict['value2'] = value2.text
	
	dict['true'] = 'END'
	dict['false'] = 'END'
	
	for connection in graph.get_connection_list():
		if connection['from_node'] == name:
			if connection['from_port'] == 0:
				dict['true'] = connection['to_node']
			elif connection['from_port'] == 1:
				dict['false'] = connection['to_node']
	
	return dict


func _from_dict(dict : Dictionary):
	value1.text = dict['value1']
	operator.selected = dict['operator']
	value2.text = dict['value2']
	
	value1.set_meta('last_value', value1.text)
	last_operator = operator.selected
	value2.set_meta('last_value', value2.text)
	
	return [dict['true'], dict['false']]


func set_value(node : LineEdit, new_value):
	if node.text != new_value:
		node.text = new_value
	node.set_meta('last_value', new_value)


func _on_value1_changed(new_text):
	value1_timer.stop()
	value1_timer.start()


func _on_value1_timer_timeout():
	if not undo_redo: return
	
	undo_redo.create_action('Set value1')
	undo_redo.add_do_method(self, 'set_value', value1, value1.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_value', value1, value1.get_meta('last_value'))
	undo_redo.commit_action()


func _on_operator_selected(idx):
	if not undo_redo: return
	
	undo_redo.create_action('Set operator')
	undo_redo.add_do_method(operator, 'select', idx)
	undo_redo.add_do_property(self, 'last_operator', idx)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(operator, 'select', last_operator)
	undo_redo.add_undo_property(self, 'last_operator', last_operator)
	undo_redo.commit_action()


func _on_value2_changed(new_text):
	value2_timer.stop()
	value2_timer.start()


func _on_value2_timer_timeout():
	if not undo_redo: return
	
	undo_redo.create_action('Set value2')
	undo_redo.add_do_method(self, 'set_value', value2, value2.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_value', value2, value2.get_meta('last_value'))
	undo_redo.commit_action()


func _on_modified():
	modified.emit()
