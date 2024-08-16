@tool
extends Control


signal value_changed


var _scatter
var _previous
var _locked := false


func set_scatter(scatter_node) -> void:
	_scatter = scatter_node


func set_parameter_name(_text: String) -> void:
	pass


func set_hint_string(_hint: String) -> void:
	pass


func set_value(val) -> void:
	_locked = true
	_set_value(val)
	_previous = get_value()
	_locked = false


func get_value():
	pass


func get_editor_theme() -> Theme:
	if not _scatter:
		return ThemeDB.get_default_theme()
	
	var editor_interface: Variant
	
	if Engine.get_version_info().minor >= 2:
		editor_interface = EditorInterface
		return editor_interface.get_editor_theme()
	else:
		editor_interface = _scatter.editor_plugin.get_editor_interface()
		return editor_interface.get_base_control().get_theme()


func _set_value(_val):
	pass


func _on_value_changed(_val) -> void:
	if not _locked:
		var value = get_value()
		if value != _previous:
			value_changed.emit(value, _previous)
		_previous = value
