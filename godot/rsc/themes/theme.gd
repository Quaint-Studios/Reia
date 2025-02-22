@tool
extends ProgrammaticTheme

class Colors:
	const SoftWhite = Color8(245, 245, 245)
	const CreamyWhite = Color8(249, 243, 229)
	const PureWhite = Color8(255, 255, 255)
	const TransparentBlack = Color8(26, 26, 26, 51)
	const ClearBlue = Color8(95, 144, 151)
	const ChipBlue = Color8(85, 142, 221)

var font_normal := ResourceLoader.load("res://rsc/fonts/Roboto/Roboto-Regular.ttf") as FontFile
var font_bold := ResourceLoader.load("res://rsc/fonts/Roboto/Roboto-Bold.ttf") as FontFile
const default_font_size := 20

func setup() -> void:
	set_save_path("res://rsc/themes/generated/game_theme.tres")

func define_theme() -> void:
	define_fonts()
	define_labels()
	define_buttons()

#region Fonts
func define_fonts() -> void:
	define_font_default()

func define_font_default() -> void:
	define_default_font(font_normal)
	define_default_font_size(default_font_size)
#endregion

#region Labels
func define_labels() -> void:
	define_label_default()
	define_mainmenulabel_label()

func define_label_default() -> void:
	define_style("Label", {
		font_color = Colors.SoftWhite
	})

func define_mainmenulabel_label() -> void:
	define_variant_style("MainMenuLabel", "Label", {
		font = font_bold,
		font_color = Colors.CreamyWhite,
		font_size = 46,
	})

	define_variant_style("MainMenuLabelHovered", "Label", {
		font = font_bold,
		font_color = Colors.PureWhite,
		font_size = 54
	})
#endregion

#region Buttons
func define_buttons() -> void:
	define_button_default()

func define_button_default() -> void:
	define_style("Button", {
		font_color = Colors.SoftWhite
	})
#endregion
