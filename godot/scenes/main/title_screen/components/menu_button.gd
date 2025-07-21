extends MarginContainer

func show_decorations(isHidden := false) -> void:
	(%DotL as TextureRect).visible = isHidden
	(%DotR as TextureRect).visible = isHidden
	(%StarL as TextureRect).visible = isHidden
	(%StarR as TextureRect).visible = isHidden

func _on_button_button_down() -> void:
	modulate.a = 0.8
	scale = Vector2(0.9,0.9)

func _on_button_button_up() -> void:
	modulate.a = 1
	scale = Vector2(1,1)

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
