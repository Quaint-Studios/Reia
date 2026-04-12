@tool
extends EditorScript

const THEME_OUTPUT_PATH = "res://client/ui/themes/generated/global_theme.tres"

func _run() -> void:
	var theme := Theme.new()

	# --- Base Fonts ---
	var title_font := preload("res://client/assets/fonts/poppins-latin-700-normal.ttf")
	var body_font := preload("res://client/assets/fonts/roboto-latin-900-normal.ttf")

	theme.default_font = body_font
	theme.default_font_size = 16

	# --- HeaderLabel Variation ---
	theme.add_type("HeaderLabel")
	theme.set_font("font", "HeaderLabel", title_font)
	theme.set_font_size("font_size", "HeaderLabel", 32)

	# --- BodyTextLabel Variation ---
	theme.add_type("BodyTextLabel")
	theme.set_font("font", "BodyTextLabel", body_font)
	theme.set_font_size("font_size", "BodyTextLabel", 18)

	# --- PrimaryActionButton Variation ---
	theme.add_type("PrimaryActionButton")
	theme.set_font("font", "PrimaryActionButton", title_font)
	theme.set_font_size("font_size", "PrimaryActionButton", 20)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = UIColors.Base.CHIP_BLUE
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.content_margin_left = 24
	btn_normal.content_margin_right = 24
	btn_normal.content_margin_top = 12
	btn_normal.content_margin_bottom = 12

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = UIColors.Base.CLEAR_BLUE

	theme.set_stylebox("normal", "PrimaryActionButton", btn_normal)
	theme.set_stylebox("hover", "PrimaryActionButton", btn_hover)
	theme.set_stylebox("pressed", "PrimaryActionButton", btn_hover)

	# Save the theme
	var dir := DirAccess.open("res://client/ui/themes/generated/")
	if not dir:
		var dir_access := DirAccess.make_dir_recursive_absolute("res://client/ui/themes/generated/")
		if dir_access != OK:
			push_error("[ThemeGen] Failed to create directory for theme output: res://client/ui/themes/generated/")
			return

	var save := ResourceSaver.save(theme, THEME_OUTPUT_PATH)
	if save != OK:
		push_error("[ThemeGen] Failed to save global theme to path: " + THEME_OUTPUT_PATH)
	else:
		print("[ThemeGen] Successfully generated global_theme.tres")
