@tool
extends RichTextEffect
class_name RichTextMatrix

# Syntax: [matrix clean=2.0 dirty=1.0 span=50][/matrix]

# Define the tag name.
var bbcode = "matrix"

# Gets TextServer for retrieving font information.
func get_text_server():
	return TextServerManager.get_primary_interface()

func _process_custom_fx(char_fx):
	# Get parameters, or use the provided default value if missing.
	var clear_time = char_fx.env.get("clean", 2.0)
	var dirty_time = char_fx.env.get("dirty", 1.0)
	var text_span = char_fx.env.get("span", 50)

	var value = char_fx.glyph_index

	var matrix_time = fmod(char_fx.elapsed_time + (char_fx.range.x / float(text_span)), clear_time + dirty_time)

	matrix_time = 0.0 if matrix_time < clear_time else (matrix_time - clear_time) / dirty_time

	if matrix_time > 0.0:
		value = int(1 * matrix_time * (126 - 65))
		value %= (126 - 65)
		value += 65
	char_fx.glyph_index = get_text_server().font_get_glyph_index(char_fx.font, 1, value, 0)
	return true
