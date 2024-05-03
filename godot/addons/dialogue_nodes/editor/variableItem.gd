@tool
extends HBoxContainer


signal modified
signal delete_requested(node)

@onready var var_name : LineEdit = $Name
@onready var type = $Type
@onready var string_value : LineEdit = $StringValue
@onready var int_value : SpinBox = $IntValue
@onready var float_value : SpinBox = $FloatValue
@onready var bool_value : CheckBox = $BoolValue

var undo_redo : EditorUndoRedoManager
var last_set_name : String
var last_set_type : int
var last_shown_input : Control
var last_value = ['', 0, 0.0, false]
var types = [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL]


func _ready():
	last_set_name = var_name.text
	last_set_type = type.selected
	last_shown_input = string_value
	last_value[0] = string_value.text
	
	for i in range(type.item_count):
		type.set_item_id(i, types[i])


func get_var_name():
	return var_name.text


func set_var_name(new_name : String):
	if new_name != var_name.text:
		var_name.text = new_name
	last_set_name = var_name.text


func get_value():
	match types[type.selected]:
		TYPE_STRING:
			return string_value.text
		TYPE_INT:
			return int_value.value
		TYPE_FLOAT:
			return float_value.value
		TYPE_BOOL:
			return bool_value.button_pressed
	return ''


func set_value(new_value):
	match types[type.selected]:
		TYPE_STRING:
			if new_value != string_value.text:
				string_value.text = str(new_value)
		TYPE_INT:
			int_value.set_value_no_signal(int(new_value))
		TYPE_FLOAT:
			float_value.set_value_no_signal(float(new_value))
		TYPE_BOOL:
			bool_value.set_pressed_no_signal(bool(new_value))
	
	last_value = [
		string_value.text,
		int_value.value,
		float_value.value,
		bool_value.button_pressed
	]


func set_type(new_idx : int):
	if last_shown_input:
		last_shown_input.hide()
	
	match types[new_idx]:
		TYPE_STRING:
			string_value.show()
			last_shown_input = string_value
		TYPE_INT:
			int_value.show()
			last_shown_input = int_value
		TYPE_FLOAT:
			float_value.show()
			last_shown_input = float_value
		TYPE_BOOL:
			bool_value.show()
			last_shown_input = bool_value
	
	last_set_type = new_idx


func get_data():
	var type = type.get_item_id(type.selected)
	var value = get_value()
	return {'type': type, 'value': value}


func load_data(new_name : String, data : Dictionary):
	set_var_name(new_name)
	type.select(types.find(data['type']))
	set_type(types.find(data['type']))
	set_value(data['value'])


func _on_name_changed(new_text):
	if not undo_redo:
		return
	
	undo_redo.create_action('Set variable name')
	undo_redo.add_do_method(self, 'set_var_name', new_text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_var_name', last_set_name)
	undo_redo.commit_action()


func _on_type_changed(new_idx: int):
	if not undo_redo:
		set_type(new_idx)
		return
	
	undo_redo.create_action('Set variable type')
	undo_redo.add_do_method(type, 'select', new_idx)
	undo_redo.add_do_method(self, 'set_type', new_idx)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(type, 'select', last_set_type)
	undo_redo.add_undo_method(self, 'set_type', last_set_type)
	undo_redo.commit_action()


func _on_value_changed(new_value):
	if not undo_redo:
		return
	
	undo_redo.create_action('Set variable value')
	undo_redo.add_do_method(self, 'set_value', new_value)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_value', last_value[type.selected])
	undo_redo.commit_action()


func _on_delete_pressed():
	delete_requested.emit(self)


func _on_modified(_a= 0, _b= 0):
	modified.emit()
