@tool
extends GraphNode


signal modified

@onready var text_edit = $TextEdit
@onready var resize_timer = $ResizeTimer
@onready var text_timer = $TextTimer

var undo_redo : EditorUndoRedoManager
var last_size := size
var last_text := ''


func _to_dict(_graph):
	var dict = {}
	
	dict['comment'] = text_edit.text
	dict['size'] = size
	
	return dict


func _from_dict(dict : Dictionary):
	if dict.has('size') and dict['size'] is Vector2:
		size = dict['size']
		last_size = size
	
	text_edit.text = dict['comment']
	last_text = text_edit.text


func set_text(new_text : String):
	if text_edit.text != new_text:
		text_edit.text = new_text
	last_text = new_text


func _on_resize(_new_size):
	resize_timer.stop()
	resize_timer.start()


func _on_resize_timer_timeout():
	if not undo_redo:
		print_rich('[shake][color="FF8866"]WOMP WOMP no undo_redo??[/color][/shake]')
		return
	
	undo_redo.create_action('Set node size')
	undo_redo.add_do_method(self, 'set_size', size)
	undo_redo.add_do_property(self, 'last_size', size)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_property(self, 'last_size', last_size)
	undo_redo.add_undo_method(self, 'set_size', last_size)
	undo_redo.commit_action()


func _on_text_changed():
	text_timer.stop()
	text_timer.start()


func _on_text_timer_timeout():
	if not undo_redo:
		return
	
	undo_redo.create_action('Set comment text')
	undo_redo.add_do_method(self, 'set_text', text_edit.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_text', last_text)
	undo_redo.commit_action()


func _on_modified():
	modified.emit()
