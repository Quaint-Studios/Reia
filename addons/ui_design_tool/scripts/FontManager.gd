extends Object

const FONT_FILE_PATTERN = "\\.ttf$"
const FONT_WEIGHT_PATTERNS = {
	"thin": "(?i)(-|_)thin",
	"extra_light": "(?i)(-|_)extralight",
	"light": "(?i)(-|_)light",
	"regular": "(?i)(-|_)regular",
	"medium": "(?i)(-|_)medium",
	"semi_bold": "(?i)(-|_)semibold",
	"bold": "(?i)(-|_)bold",
	"extra_bold": "(?i)(-|_)extrabold",
	"black": "(?i)(-|_)black",
	"extra_black": "(?i)(-|_)extrablack"
}
const FONT_ITALIC_PATTERN = "(?i)italic"
const FONT_ITALIC_ONLY_PATTERN = "(?i)(-|_)italic"
const FONT_VARIABLE_PATTERN = "(?i)(-|_)variable"
var FONT_FORMATTINGS = {
	"Heading 1": FontFormatting.new("light", 96, -3),
	"Heading 2": FontFormatting.new("light", 60, -2),
	"Heading 3": FontFormatting.new("regular", 48),
	"Heading 4": FontFormatting.new("regular", 34, 1),
	"Heading 5": FontFormatting.new("regular", 24),
	"Heading 6": FontFormatting.new("medium", 20, 1),
	"Subtitle 1": FontFormatting.new("regular", 16),
	"Subtitle 2": FontFormatting.new("medium", 14, 1),
	"Body 1": FontFormatting.new("regular", 16, 1),
	"Body 2": FontFormatting.new("regular", 14, 1),
	"Button": FontFormatting.new("medium", 14, 1),
	"Caption": FontFormatting.new("regular", 12, 1),
	"Overline": FontFormatting.new("regular", 10)
} # Typography hierarchy presets, see https://material.io/design/typography/the-type-system.html#type-scale
const DIR_FOLDER_PATTERN = "\\w+(?!.*\\w)"

var font_families = {}

var _font_file_regex = RegEx.new()
var _font_weight_regexes = {
	"thin": RegEx.new(),
	"extra_light": RegEx.new(),
	"light": RegEx.new(),
	"regular": RegEx.new(),
	"medium": RegEx.new(),
	"semi_bold": RegEx.new(),
	"bold": RegEx.new(),
	"extra_bold": RegEx.new(),
	"black": RegEx.new(),
	"extra_black": RegEx.new()
}
var _font_italic_regex = RegEx.new()
var _font_italic_only_regex = RegEx.new()
var _font_variable_regex = RegEx.new()
var _dir_folder_regex = RegEx.new()


func _init():
	if _font_file_regex.compile(FONT_FILE_PATTERN):
		print("Failed to compile ", FONT_FILE_PATTERN)

	for font_weight in _font_weight_regexes.keys():
		if _font_weight_regexes[font_weight].compile(FONT_WEIGHT_PATTERNS[font_weight]):
			print("Failed to compile ", FONT_WEIGHT_PATTERNS[font_weight])

	if _font_italic_regex.compile(FONT_ITALIC_PATTERN):
		print("Failed to compile ", FONT_ITALIC_PATTERN)

	if _font_italic_only_regex.compile(FONT_ITALIC_ONLY_PATTERN):
		print("Failed to compile ", FONT_ITALIC_ONLY_PATTERN)

	if _font_variable_regex.compile(FONT_VARIABLE_PATTERN):
		print("Failed to compile ", FONT_VARIABLE_PATTERN)

	if _dir_folder_regex.compile(DIR_FOLDER_PATTERN):
		print("Failed to compile ", DIR_FOLDER_PATTERN)

# Load root dir of font resources, check Readme for directory structure
func load_root_dir(root_dir):
	var directory = DirAccess.open(root_dir)
	var result = DirAccess.get_open_error()
	if result == OK:
		font_families.clear()
		directory.list_dir_begin()  # Skip . and .. directory and hidden# TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var dir = directory.get_next()
		while dir != "":
			if not directory.current_is_dir():
				dir = directory.get_next()
				continue

			load_fonts(directory.get_current_dir() + "/" + dir)
			dir = directory.get_next()
		directory.list_dir_end()
	else:
		push_warning("UI Design Tool: An error occurred when trying to access %s, ERROR: %d" % [root_dir, result])
		return false

	return true

# Load fonts data from directory, check Readme for filename pattern
func load_fonts(dir):
	var directory = DirAccess.open(dir)
	var result = DirAccess.get_open_error()
	if result == OK:
		var font_family_name = _dir_folder_regex.search(dir).get_string()
		var font_family = FontFamily.new(font_family_name)
		directory.list_dir_begin()
		var filename = directory.get_next()
		while filename != "":
			if directory.current_is_dir():
				filename = directory.get_next()
				continue

			if _font_file_regex.search(filename):
				for font_weight in _font_weight_regexes.keys():
					if _font_variable_regex.search(filename): # Godot doesn't support variable font
						continue

					var abs_dir = directory.get_current_dir() + "/" + filename
					if _font_weight_regexes[font_weight].search(filename):
						var font_data = load(abs_dir)
						
						if _font_italic_regex.search(filename):
							font_family.set_font_face(FontFace.new(font_family.name, font_weight, font_data, FONT_STYLE.ITALIC))
						else:
							font_family.set_font_face(FontFace.new(font_family.name, font_weight, font_data))
						break
					else: 
						# Capture regular italic from {font-name}-italic.ttf
						if _font_italic_only_regex.search(filename):
							var font_data = load(abs_dir)
							font_family.set_font_face(FontFace.new(font_family.name, "regular", font_data, FONT_STYLE.ITALIC))
							break
			filename = directory.get_next()
		directory.list_dir_end()

		if not font_family.is_empty():
			font_families[font_family.name] = font_family
		else:
			push_warning("UI Design Tool: Unable to locate usable .ttf files from %s, check README.md for proper directory/filename structure" % dir)
	else:
		push_warning("UI Design Tool: An error occurred when trying to access %s, ERROR: %d" % [dir, result])
		return false

	return true

func get_font_face(font_data):
	for res in font_families.values():
		for font_weight in FONT_WEIGHT.keys():
			var font_faces = res.get(font_weight)
			for font_face in font_faces.values():
				if font_face.data and font_data:
					if font_face.data.resource_path == font_data.resource_path:
						return font_face
	return null 

# Find font resource with font name
func get_font_family(font_family_name):
	return font_families.get(font_family_name)

static func get_font_style_str(font_style):
	return FONT_STYLE.keys()[font_style].to_lower()

# Declaration of font type with font_faces
class FontFamily:
	var name = ""
	var thin = {}
	var extra_light = {}
	var light = {}
	var regular = {}
	var medium = {}
	var semi_bold = {}
	var bold = {}
	var extra_bold = {}
	var black = {}
	var extra_black = {}

	func _init(n):
		name = n

	func set_font_face(font_face):
		var font_faces = get(font_face.font_weight.replace('-', '_'))
		font_faces[FONT_STYLE.keys()[font_face.font_style].to_lower()] = font_face

	func is_empty():
		for font_weight in FONT_WEIGHT.keys():
			var font_faces = get(font_weight)
			if not font_faces.values().is_empty():
				return false
		return true

	func get_class():
		return "FontFamily"

# Font face data, see (https://developer.mozilla.org/my/docs/Web/CSS/@font-face)
class FontFace:
	var font_family = ""
	var font_weight = ""
	var font_style = FONT_STYLE.NORMAL
	var data

	func _init(ff, fw, d, fs=FONT_STYLE.NORMAL):
		font_family = ff
		font_weight = fw
		font_style = fs
		data = d

	func get_class():
		return "FontFace"

# Declaration of font style TODO: Custom resource to define font style
class FontFormatting:
	var font_weight = "regular"
	var font_style = 0 # FONT_STYLE.NORMAL
	var size = 16
	var letter_spacing = 0

	func _init(fw, s, ls=0):
		font_weight = fw
		size = s
		letter_spacing = ls

# List of font style, see (https://developer.mozilla.org/my/docs/Web/CSS/font-style)
enum FONT_STYLE {
	NORMAL,
	ITALIC,
	OBLIQUE
}

# List of font weights, see (https://docs.microsoft.com/en-us/typography/opentype/spec/os2#usweightclass)
const FONT_WEIGHT = {
	"thin": 100,
	"extra_light": 200,
	"light": 300,
	"regular": 400,
	"medium": 500,
	"semi_bold": 600,
	"bold": 700,
	"extra_bold": 800,
	"black": 900
}
