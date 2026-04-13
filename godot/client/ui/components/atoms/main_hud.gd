class_name MainHUD extends Control
## Replaces the Title Screen and handles in-game overlays like Chat and Health

func _ready() -> void:
	# Build layout dynamically to ensure it scales flawlessly on any resolution
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var chat := ChatBox.new()
	chat.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	chat.position = Vector2(20, get_viewport_rect().size.y - 270)
	add_child(chat)
