@tool
extends GraphNode


signal modified

@onready var value = $SignalValue
@onready var timer = $Timer

var undo_redo : EditorUndoRedoManager
var last_value := ''


func _to_dict(graph : GraphEdit):
	var dict = {}
	var connections = graph.get_connections(name)
	
	dict['signalValue'] = value.text
	dict['link'] = connections[0]['to_node'] if connections.size() > 0 else 'END'
	
	return dict


func _from_dict(dict : Dictionary):
	value.text = dict['signalValue']
	last_value = value.text
	
	return [dict['link']]


func set_value(new_value : String):
	if value.text != new_value:
		value.text = new_value
	last_value = new_value


func _on_signal_value_changed(_new_text):
	timer.stop()
	timer.start()


func _on_timer_timeout():
	if not undo_redo: return
	
	undo_redo.create_action('Set signal value')
	undo_redo.add_do_method(self, 'set_value', value.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_value', last_value)
	undo_redo.commit_action()


func _on_modified():
	modified.emit()
