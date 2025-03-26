@tool
extends EditorScript
class_name ProgrammaticTheme
## The core class in ThemeGen that allows for the creation
## of themes through GDScript code.
##
## Run the theme generator via File/Run when editing the theme GDScript file.
## Alternatively, the hot-reload plugin can be used by... [br]
## ... enabling the hot reload plugin [br]
## ... and adding the following [b]const[/b] variable in the child script:
## [codeblock]
## const UPDATE_ON_SAVE = true
## [/codeblock]
##
## See the README for more information: 
## [url]https://github.com/Inspiaaa/ThemeGen[/url]


const THEME_GEN_VERSION = "1.3.1"


## Determines the verbosity of the logging. 
## It applies to the theme generator and the hot reload plugin. [br]
## The verbosity level of the logging can be configured by adding the following
## [b]const[/b] variable in the child script:
## [codeblock]
## const VERBOSITY = Verbosity.SILENT # or other option.
## [/codeblock]
enum Verbosity { 
	## No logging (except for errors).
	SILENT = 0, 
	## Only the most important messages are logged.
	QUIET = 1, 
	## Detailed logging.
	NORMAL = 2 
}

# Logging levels that correspond to the Verbosity levels.
enum _LoggingLevel { 
	INFO = 1, # For Verbosity.QUIET and higher.
	DEBUG = 2  # For Verbosity.NORMAL and higher.
}


var _styles_by_name = {}
var _variant_to_parent_type_name = {}

var _default_font = null
var _default_font_size = null

var _save_path = null

# The function that is run to generate / define the theme. Default: define_theme().
var _theme_generator = null

# The default theme is used to get the base type for each theme variation.
# Previoiusly, it was also used to get the data type of each item (e.g. is a 
# given integer a constant or a font size?). If the ClassDB property lookup fails,
# this system could be used as a fallback in future versions.
var _default_theme: Theme

# Current theme instance used by the generator.
var _current_theme: Theme


## Dictionary that contains the styles defined via 
## [method define_style] and [method define_variant_style], 
## mapping each type name to the corresponding style data.
var styles: Dictionary:
	get:
		return _styles_by_name

## Returns the current [Theme] instance (of the current theme variant being 
## processed in define_theme), allowing you to add custom properties.
var current_theme: Theme:
	get:
		assert(_current_theme != null, "The current theme instance can only be accessed from within define_theme().") 
		return _current_theme


# In a subclass, the developer should create a method called setup() or multiple
# method starting with the prefix setup_ to define the theme or theme variants.
# In these methods, the developer should call set_save_path().


func define_theme():
	# This method is to be overwritten by the developer in a subclass.
	pass


func set_save_path(path: String):
	_save_path = path


func set_theme_generator(generator: Callable):
	_theme_generator = generator


func define_style(name: String, style: Dictionary):
	_styles_by_name[name] = style


func define_variant_style(name: String, base_type_name: String, style: Dictionary = {}):
	_variant_to_parent_type_name[name] = base_type_name
	define_style(name, style)


func define_default_font(font: Font):
	_default_font = font


func define_default_font_size(size: int):
	_default_font_size = size


func inherit(base_style: Dictionary, style2=null, style3=null, style4=null, style5=null, style6=null, style7=null, style8=null):
	var inherited_style = base_style.duplicate()

	for style in [style2, style3, style4, style5, style6, style7, style8]:
		if style != null:
			inherited_style.merge(style, true)

	return inherited_style


func merge(style1: Dictionary, style2, style3=null, style4=null, style5=null, style6=null, style7=null, style8=null):
	return inherit(style1, style2, style3, style4, style5, style6, style7, style8)


func copy(style: Dictionary):
	return style.duplicate()


func include(main_style: Dictionary, style1, style2=null, style3=null, style4=null, style5=null, style6=null, style7=null, style8=null):
	for style in [style1, style2, style3, style4, style5, style6, style7, style8]:
		if style != null:
			main_style.merge(style, true)


func stylebox_flat(style: Dictionary):
	var as_dictionary = {"type": "stylebox_flat"}
	as_dictionary.merge(style)
	return as_dictionary

func stylebox_line(style: Dictionary):
	var as_dictionary = {"type": "stylebox_line"}
	as_dictionary.merge(style)
	return as_dictionary

func stylebox_empty(style: Dictionary):
	var as_dictionary = {"type": "stylebox_empty"}
	as_dictionary.merge(style)
	return as_dictionary

func stylebox_texture(style: Dictionary):
	var as_dictionary = {"type": "stylebox_texture"}
	as_dictionary.merge(style)
	return as_dictionary


func _run():
	_default_theme = ThemeDB.get_default_theme()

	var setup_functions = _discover_theme_setup_functions()
	_debug_raw("=== ThemeGen v%s by Inspiaaa ===" % THEME_GEN_VERSION)
	_info("Discovered %s theme(s)." % len(setup_functions))

	for theme in setup_functions:
		_info("--- %s ---" % theme)
		_generate_theme(theme)
		_info("---")
	_debug_raw("===")


func _discover_theme_setup_functions():
	var setup_function_names = []

	for method in get_method_list():
		if method.name.begins_with("setup") and method.flags == METHOD_FLAG_NORMAL:
			setup_function_names.append(method.name)

	var unique_function_names = []
	for name in setup_function_names:
		if name not in unique_function_names:
			unique_function_names.append(name)

	return unique_function_names.map(get)


func _generate_theme(setup_function: Callable):
	_reset()
	_debug("Setting up theme generation.... (%s)" % setup_function)
	setup_function.call()

	if _save_path == null:
		push_error("Save path must be set before generating the theme. (See set_save_path(...))")
		return

	_debug("Generating theme... (%s)" % _theme_generator)
	var theme = Theme.new()
	
	# Make the current theme instance available during define_theme().
	_current_theme = theme
	_theme_generator.call()
	_current_theme = null

	_debug("Loading default font...")
	_load_default_font(theme)

	_debug("Loading variants...")
	_load_variants(theme)

	_debug("Loading styles...")
	for type_name in _styles_by_name:
		_debug("> Style '%s':" % type_name)
		var style = _styles_by_name[type_name]

		_debug("  > Preprocessing...")
		style = style.duplicate()
		_preprocess_style(style)

		_debug("  > Loading...")
		_load_style(theme, type_name, style)

	_info("Saving to '%s'..." % _save_path)
	_save_theme(theme)
	_debug("Theme generation finished.")


func _reset():
	_styles_by_name = {}
	_variant_to_parent_type_name = {}

	_default_font = null
	_default_font_size = null
	_save_path = null
	_current_theme = null
	_theme_generator = define_theme


func _save_theme(theme: Theme):
	_update_existing_theme_instance(theme)
	ResourceSaver.save(theme, _save_path)


func _update_existing_theme_instance(new_theme: Theme):
	# When the editor uses the generated theme file, it loads the resource into
	# memory. This means that when the new theme is saved, the existing one in
	# memory is not updated or invalidated until the editor is restarted,
	# leaving the UI unaffected. 
	# To fix this issue, the cached theme resource in memory is fetched and 
	# mutated in-place (using the fact that when a resource is loaded, Godot uses
	# the shared instance in memory instead of loading a new instance from disk).
	
	if not ResourceLoader.exists(_save_path):
		return
	
	var existing_theme = load(_save_path)
	if not existing_theme is Theme:
		return
	
	_debug("Updating cached theme instance...")
	existing_theme.clear()
	existing_theme.merge_with(new_theme)


func _load_default_font(theme: Theme):
	if _default_font != null:
		theme.default_font = _default_font
	if _default_font_size != null:
		theme.default_font_size = _default_font_size


func _load_variants(theme: Theme):
	for variant_name in _variant_to_parent_type_name:
		theme.add_type(variant_name)

	for variant_name in _variant_to_parent_type_name:
		var parent_name = _variant_to_parent_type_name[variant_name]
		theme.set_type_variation(variant_name, parent_name)


func _load_style(theme: Theme, type_name: String, style: Dictionary):
	theme.add_type(type_name)

	for item_name in style:
		var item_value = style[item_name]
		_load_style_item(theme, type_name, item_name, item_value)


func _preprocess_style(style: Dictionary):
	# Copy the keys, as the dictionary is modified in-place during iteration.
	var keys = style.keys()
	for key in keys:
		var value = style[key]
		if value is Dictionary:
			_preprocess_style(value)

		if key.ends_with("_"):
			_merge_sub_dict_into_main_dict(style, key)


func _merge_sub_dict_into_main_dict(main_dict: Dictionary, sub_dict_name: String):
	var sub_dict = main_dict[sub_dict_name]
	if not sub_dict is Dictionary:
		return

	for key in sub_dict:
		main_dict[key] = sub_dict[key]

	main_dict.erase(sub_dict_name)


func _load_style_item(theme: Theme, type_name: String, item_name: String, value):
	var data_type = _get_data_type_for_value(_default_theme, theme, type_name, item_name)
	if data_type == -1:
		push_error("Item name '%s' not recognized for type '%s'." % [item_name, type_name])
		return

	if data_type == Theme.DATA_TYPE_STYLEBOX:
		value = _create_stylebox_from_dict(value)

	theme.set_theme_item(data_type, item_name, type_name, value)


func _create_stylebox_from_dict(data: Dictionary):
	var type = data["type"]
	var stylebox: StyleBox

	match type:
		"stylebox_flat":
			stylebox = StyleBoxFlat.new()
		"stylebox_line":
			stylebox = StyleBoxLine.new()
		"stylebox_empty":
			stylebox = StyleBoxEmpty.new()
		"stylebox_texture":
			stylebox = StyleBoxTexture.new()

	for attribute in data:
		if attribute == "type":
			continue
		var value = data[attribute]
		stylebox.set(attribute, value)

	return stylebox


func _get_data_type_for_value(default_theme: Theme, theme: Theme, type_name, item_name):
	if _type_has_color_item(type_name, item_name):
		return Theme.DATA_TYPE_COLOR
	if _type_has_constant_item(type_name, item_name):
		return Theme.DATA_TYPE_CONSTANT
	if _type_has_font_item(type_name, item_name):
		return Theme.DATA_TYPE_FONT
	if _type_has_font_size_item(type_name, item_name):
		return Theme.DATA_TYPE_FONT_SIZE
	if _type_has_icon_item(type_name, item_name):
		return Theme.DATA_TYPE_ICON
	if _type_has_style_item(type_name, item_name):
		return Theme.DATA_TYPE_STYLEBOX

	# This type does not contain this item. => Check the parent type.
	var parent = theme.get_type_variation_base(type_name)

	if parent == "":
		parent = default_theme.get_type_variation_base(type_name)

	if parent == "":
		return -1

	return _get_data_type_for_value(default_theme, theme, parent, item_name)


func _type_has_color_item(type_name: String, item_name: String):
	return _type_has_property(type_name, "theme_override_colors/" + item_name)
	
func _type_has_constant_item(type_name: String, item_name: String):
	return _type_has_property(type_name, "theme_override_constants/" + item_name)
	
func _type_has_font_item(type_name: String, item_name: String):
	return _type_has_property(type_name, "theme_override_fonts/" + item_name)
	
func _type_has_font_size_item(type_name: String, item_name: String):
	return _type_has_property(type_name, "theme_override_font_sizes/" + item_name)
	
func _type_has_icon_item(type_name: String, item_name: String):
	return _type_has_property(type_name, "theme_override_icons/" + item_name)
	
func _type_has_style_item(type_name: String, item_name: String):
	return _type_has_property(type_name, "theme_override_styles/" + item_name)


func _type_has_property(type_name: String, property_name: String):
	if not ClassDB.class_exists(type_name):
		return false
	
	var properties = ClassDB.instantiate(type_name).get_property_list()
	return properties.any(func(property): return property.name == property_name)


func _debug(message: String):
	_log_raw(_LoggingLevel.DEBUG, "[ThemeGen] " + message)

func _debug_raw(message: String):
	_log_raw(_LoggingLevel.DEBUG, message)

func _info(message: String):
	_log_raw(_LoggingLevel.INFO, "[ThemeGen] " + message)

func _info_raw(message: String):
	_log_raw(_LoggingLevel.INFO, message)

func _log_raw(level: _LoggingLevel, message: String):
	if level <= _get_logging_level():
		print(message)

func _get_logging_level():
	var level = get("VERBOSITY")
	return Verbosity.NORMAL if level == null else level


func border_width(left: int, top = null, right = null, bottom = null):
	if top == null: top = left
	if right == null: right = left
	if bottom == null: bottom = top

	return {
		"border_width_left": left,
		"border_width_top": top,
		"border_width_right": right,
		"border_width_bottom": bottom
	}


func corner_radius(top_left: int, top_right = null, bottom_right = null, bottom_left = null):
	if top_right == null: top_right = top_left
	if bottom_right == null: bottom_right = top_right
	if bottom_left == null: bottom_left = top_left

	return {
		"corner_radius_top_left": top_left,
		"corner_radius_top_right": top_right,
		"corner_radius_bottom_right": bottom_right,
		"corner_radius_bottom_left": bottom_left
	}


func expand_margins(left: int, top = null, right = null, bottom = null):
	if top == null: top = left
	if right == null: right = left
	if bottom == null: bottom = top

	return {
		"expand_margin_left": left,
		"expand_margin_top": top,
		"expand_margin_right": right,
		"expand_margin_bottom": bottom
	}


func content_margins(left: int, top = null, right = null, bottom = null):
	if top == null: top = left
	if right == null: right = left
	if bottom == null: bottom = top

	return {
		"content_margin_left": left,
		"content_margin_top": top,
		"content_margin_right": right,
		"content_margin_bottom": bottom
	}


func texture_margins(left: int, top = null, right = null, bottom = null):
	if top == null: top = left
	if right == null: right = left
	if bottom == null: bottom = top

	return {
		"texture_margin_left": left,
		"texture_margin_top": top,
		"texture_margin_right": right,
		"texture_margin_bottom": bottom
	}
