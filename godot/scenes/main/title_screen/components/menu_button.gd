extends Node

func show_decorations(hidden := false) -> void:
	(%DotL as TextureRect).visible = hidden
	(%DotR as TextureRect).visible = hidden
	(%StarL as TextureRect).visible = hidden
	(%StarR as TextureRect).visible = hidden

func hover() -> void:
	(%Label as Label).theme_type_variation = &"MainMenu_Hovered"
	show_decorations(true)
func normal() -> void:
	(%Label as Label).theme_type_variation = &"MainMenu"
	show_decorations(false)

func _on_button_mouse_entered() -> void:
	(%Button as Button).grab_focus()
	hover()
func _on_button_mouse_exited() -> void:
	normal()

func _on_button_focus_entered() -> void:
	hover()
func _on_button_focus_exited() -> void:
	normal()
