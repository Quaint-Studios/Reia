@tool
extends ProgrammaticTheme

class Colors:
	class White:
		const PURE = Color8(255, 255, 255)
		const CREAMY = Color8(249, 243, 229)
		const SOFT = Color8(245, 245, 245)
	class Black:
		const TRANSPARENT = Color8(26, 26, 26, 51) # 20% alpha
		const DEBUG = Color8(7, 38, 61, 127.5) # 50% alpha
	class Blue:
		const CLEAR = Color8(95, 144, 151)
		const CHIP = Color8(85, 142, 221)
	class Red:
		const CANCEL = Color8(249, 98, 47)
	class Inventory:
		const BAR = Color8(56, 90, 166, 165.75) # 65% alpha
		const CONTENT = Color8(255, 255, 255, 25.5) # 10% alpha
		class Item:
			const COMMON = Color8(85, 221, 99)
			const UNCOMMON = Color8(85, 126, 221)
			const RARE = Color8(247, 237, 186)
			const SACRED = Color8(186, 84, 248)
			const ARCANE_1 = Color8(248, 87, 32)
			const ARCANE_2 = Color8(250, 128, 87)
			const RADIANT_1 = Color8(240, 211, 66)
			const RADIANT_2 = Color8(255, 255, 255)
			const TEXT_BG = Color8(52, 51, 63)
			const TEXT_FG = Color8(250, 253, 255)
			const HEADER_BG = Color8(52, 51, 63, 127.5) # 50% alpha
			const HEADER_FG = Color8(250, 253, 255)

class Fonts:
	class Size:
		const NORMAL = 20
	class Poppins:
		static var normal := ResourceLoader.load("res://rsc/fonts/poppins-latin-400-normal.ttf") as FontFile
		static var bold := ResourceLoader.load("res://rsc/fonts/poppins-latin-700-normal.ttf") as FontFile
	class Roboto:
		static var black := ResourceLoader.load("res://rsc/fonts/roboto-latin-900-normal.ttf") as FontFile

func setup() -> void:
	set_save_path("res://rsc/themes/theme.tres")

func define_theme() -> void:
	define_fonts()
	define_labels()
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

#region Buttons
func define_buttons() -> void:
	define_button_default()

func define_button_default() -> void:
	define_style("Button", {
		font_color = Colors.White.SOFT
	})
#endregion
