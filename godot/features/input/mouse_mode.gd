class_name MouseMode
extends Node

func _unhandled_input(event: InputEvent) -> void:
	# Escape key releases mouse
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Any mouse button click (while visible) captures mouse
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
