@tool
extends HBoxContainer

signal modified
signal text_changed(new_text: String)

@onready var line_edit = $LineEdit
@onready var filter_button = $FilterButton
@onready var filter_panel = $FilterPanel
@onready var value1 = $FilterPanel/HBoxContainer/Value1
@onready var operator = $FilterPanel/HBoxContainer/Operator
@onready var value2 = $FilterPanel/HBoxContainer/Value2
@onready var reset_button = $FilterPanel/HBoxContainer/ResetButton

var undo_redo : EditorUndoRedoManager
var text := ''
var cur_condition := {}
var filter_popup_offset := 50


func set_text(new_text : String):
	if line_edit.text != new_text:
		line_edit.text = new_text
		filter_button.visible = new_text != ''
	text = new_text


func get_condition():
	var dict = {}
	
	if operator.selected > -1:
		dict['value1'] = value1.text
		dict['operator'] = operator.selected
		dict['value2'] = value2.text
	
	return dict


func set_condition(new_condition: Dictionary):
	if new_condition.is_empty():
		value1.text = ''
		operator.selected = -1
		value2.text = ''
	else:
		if value1.text != new_condition['value1']:
			value1.text = new_condition['value1']
		operator.selected = new_condition['operator']
		if value2.text != new_condition['value2']:
			value2.text = new_condition['value2']
	cur_condition = new_condition
	
	# update condition buttons
	if value1.text == '' and operator.selected == -1 and value2.text == '':
		reset_button.hide()
		filter_button.text = ''
		return
	
	filter_button.text = '*'
	reset_button.show()


func _on_filter_button_pressed():
	var popup_pos = global_position + filter_button.position + Vector2(0, filter_button.size.y + size.y + filter_popup_offset)
	filter_panel.popup(Rect2i(popup_pos, filter_panel.size))


func _on_text_changed(new_text : String):
	filter_button.visible = new_text != ''
	text_changed.emit(new_text)


func _on_text_focus_exited():
	focus_exited.emit()


func _on_condition_changed(_a= 0):
	if not undo_redo: return
	
	var new_condition = get_condition()
	
	if (value1.text != '' or value2.text != '') and operator.selected == -1:
		print_debug('You must select comparison operator first!')
		set_condition(new_condition)
		return
	
	undo_redo.create_action('Set condition')
	undo_redo.add_do_method(self, 'set_condition', new_condition)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_condition', cur_condition)
	undo_redo.commit_action()


func _on_condition_reset():
	if not undo_redo: return
	
	var new_condition = {}
	
	undo_redo.create_action('Reset condition')
	undo_redo.add_do_method(self, 'set_condition', new_condition)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_condition', cur_condition)
	undo_redo.commit_action()


func _on_modified():
	modified.emit()
