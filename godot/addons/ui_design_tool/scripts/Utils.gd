static func markup_text_edit_selection(text_edit, start_text, end_text):
	if not text_edit.is_selection_active():
		return

	var selection_from_pos = Vector2(text_edit.get_selection_from_column(), text_edit.get_selection_from_line())
	var selection_to_pos = Vector2(text_edit.get_selection_to_column(), text_edit.get_selection_to_line())
	var one_line_selection = selection_from_pos.y == selection_to_pos.y

	text_edit.deselect()
	set_text_edit_cursor_pos(text_edit, selection_from_pos.x, selection_from_pos.y)
	text_edit.insert_text_at_cursor(start_text)

	if one_line_selection:
		selection_to_pos.x += start_text.length()

	set_text_edit_cursor_pos(text_edit, selection_to_pos.x, selection_to_pos.y)
	text_edit.insert_text_at_cursor(end_text)

	if one_line_selection:
		selection_to_pos.x += end_text.length()

	text_edit.select(selection_from_pos.y, selection_from_pos.x, selection_to_pos.y, selection_to_pos.x)

static func get_text_edit_cursor_pos(text_edit):
	return Vector2(text_edit.get_caret_column(), text_edit.get_caret_line())

static func set_text_edit_cursor_pos(text_edit, column, line):
	text_edit.set_caret_column(column)
	text_edit.set_caret_line(line)

# Position Popup near to its target while within window, solution from ColorPickerButton source code(https://github.com/godotengine/godot/blob/6d8c14f849376905e1577f9fc3f9512bcffb1e3c/scene/gui/color_picker.cpp#L878)
static func popup_on_target(popup, target):
	popup.size = popup.get_contents_minimum_size()
	var usable_rect = Rect2(Vector2.ZERO, DisplayServer.window_get_size())
	var cp_rect = Rect2(Vector2.ZERO, popup.get_size())
	for i in 4:
		if i > 1:
			cp_rect.position.y = target.global_position.y - cp_rect.size.y
		else:
			cp_rect.position.y = target.global_position.y + target.get_size().y

		if i & 1:
			cp_rect.position.x = target.global_position.x
		else:
			cp_rect.position.x = target.global_position.x - max(0, cp_rect.size.x - target.get_size().x)

		if usable_rect.encloses(cp_rect):
			break
	popup.set_position(cp_rect.position)
	popup.popup()

# Roughly calculate the display size of option button regarding to the display_text
static func get_option_button_display_size(option_button, display_text):
	# TODO: Improve accuracy
	# Use default theme if not assingned
	var theme = option_button.get_theme() if option_button.get_theme() else Theme.new()
	var string_size = theme.get_font("font", "fonts").get_string_size(display_text)
	var arrow_icon = theme.get_icon("arrow", "styles")
	# Takes arrow icon size into account
	string_size.x += arrow_icon.get_width()
	return string_size
