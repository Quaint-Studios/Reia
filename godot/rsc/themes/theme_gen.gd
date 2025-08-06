@tool
extends ProgrammaticTheme

class Colors:
	class White:
		const PURE = Color("#FFFFFF")
		const CREAMY = Color("#F9F3E5")
		const SOFT = Color("#F5F5F5")
	class Black:
		const TRANSPARENT = Color("#1A1A1A", 0.2)
		const DEBUG = Color("#07263D", 0.5)
	class Blue:
		const CLEAR = Color("#5F9097")
		const CHIP = Color("#558EDD")
	class Red:
		const CANCEL = Color("#F9622F")
	class Inventory:
		const BAR = Color("#385AA6", 0.65)
		const CONTENT = Color("#FFFFFF", 0.1) # 10% alpha
		class Item:
			const COMMON = Color("#55DD63")
			const UNCOMMON = Color("#557EDD")
			const RARE = Color("#F7EDBA")
			const SACRED = Color("#BA54F8")
			const ARCANE_1 = Color("#F85720")
			const ARCANE_2 = Color("#FA8057")
			const RADIANT_1 = Color("#F0D342")
			const RADIANT_2 = Color("#FFFFFF")
			const TEXT_BG = Color("#34333F")
			const TEXT_FG = Color("#FAFDFF")
			const HEADER_BG = Color("#34333F", 0.5)
			const HEADER_FG = Color("#FAFDFF")

class Fonts:
	class Size:
		const NORMAL = 20
	class Poppins:
		static var normal := ResourceLoader.load("res://assets/fonts/poppins-latin-400-normal.ttf") as FontFile
		static var bold := ResourceLoader.load("res://assets/fonts/poppins-latin-700-normal.ttf") as FontFile
	class Roboto:
		static var black := ResourceLoader.load("res://assets/fonts/roboto-latin-900-normal.ttf") as FontFile

func setup() -> void:
	set_save_path("res://rsc/themes/theme.tres")

func define_theme() -> void:
	define_fonts()
	define_labels()
	define_panels()
	define_buttons()

#region Fonts
func define_fonts() -> void:
	define_font_default()

func define_font_default() -> void:
	define_default_font(Fonts.Poppins.normal)
	define_default_font_size(Fonts.Size.NORMAL)
#endregion

#region Labels
func define_labels() -> void:
	define_label_default()
	define_mainmenulabel_label()

func define_label_default() -> void:
	define_style("Label", {
		font_color = Colors.White.SOFT
	})

	define_variant_style("Roboto_Black_20_BlueChip", "Label", {
		font = Fonts.Roboto.black,
		font_color = Colors.Blue.CHIP,
		font_size = 20
	})

	define_variant_style("Poppins_Bold_18_Debug", "Label", {
		font = Fonts.Poppins.bold,
		font_color = Colors.Black.DEBUG,
		font_size = 18
	})

func define_mainmenulabel_label() -> void:
	define_variant_style("MainMenu", "Label", {
		font = Fonts.Poppins.bold,
		font_color = Colors.White.CREAMY,
		font_size = 46,
	})

	define_variant_style("MainMenu_Hovered", "Label", {
		font = Fonts.Poppins.bold,
		font_color = Colors.White.PURE,
		font_size = 54,
	})
#endregion

#region Panels
func define_panels() -> void:
	define_panel_default()
	define_panel_circle()

func define_panel_default() -> void:
	define_style("Panel", {
		panel = stylebox_empty({})
	})

func define_panel_circle() -> void:
	var style: Dictionary = stylebox_flat({
		corners_ = corner_radius(48)
	})
	define_variant_style("48r_Circle_BlueChip", "Panel", {
		panel = inherit(style, {
			bg_color = Colors.Blue.CHIP
		})
	})

#endregion

#region Buttons
func define_buttons() -> void:
	define_button_default()
	define_button_24r()

func define_button_default() -> void:
	define_style("Button", {
		font_color = Colors.White.SOFT,
		focus = stylebox_empty({}),
		hover = stylebox_empty({})
	})

func define_button_24r() -> void:
	var style: Dictionary = stylebox_flat({
		borders_ = border_width(0),
		corners_ = corner_radius(24)
	})

	var white_creamy: Dictionary = inherit(style, {
		bg_color = Colors.White.CREAMY
	})
	var white_creamy_hover: Dictionary = inherit(white_creamy, {
		borders_ = border_width(2),
		border_color = Colors.Blue.CHIP
	})
	var white_creamy_pressed: Dictionary = inherit(white_creamy_hover, {
		bg_color = Colors.White.SOFT
	})
	define_variant_style("24r_WhiteCreamy", "Button", {
		normal = white_creamy,
		hover = white_creamy_hover,
		pressed = white_creamy_pressed
	})
#endregion
