extends CanvasLayer
## AUTOLOAD: UIModalManager
## Dynamically builds and handles global notifications and confirmation dialogues.

var _notif_panel: PanelContainer
var _notif_title: Label
var _notif_msg: Label

var _confirm_panel: PanelContainer
var _confirm_title: Label
var _confirm_msg: Label
var _yes_callable: Callable
var _btn_yes: Button
var _btn_no: Button

func _ready() -> void:
	layer = 100 # Always on top of normal UI and 3D world
	_build_notification_ui()
	_build_confirmation_ui()

# ==========================================
# PUBLIC API
# ==========================================

func show_notification(title: String, message: String) -> void:
	_notif_title.text = title
	_notif_msg.text = message

	# Tween it in from the right side
	_notif_panel.position.x = get_viewport().get_visible_rect().size.x + 10
	_notif_panel.show()

	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var _tween_prop := t.tween_property(_notif_panel, "position:x", get_viewport().get_visible_rect().size.x - 320, 0.4)

	# Auto hide after 3 seconds
	UIUtils.safe_connect(get_tree().create_timer(3.0).timeout, _hide_notification, "UIModalManager _hide_notification")

func ask_confirmation(title: String, question: String, on_yes: Callable) -> void:
	_confirm_title.text = title
	_confirm_msg.text = question
	_yes_callable = on_yes
	_confirm_panel.show()

# ==========================================
# INTERNAL LOGIC
# ==========================================

func _hide_notification() -> void:
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var _tween_prop := t.tween_property(_notif_panel, "position:x", get_viewport().get_visible_rect().size.x + 10, 0.3)
	var _callback := t.tween_callback(_notif_panel.hide)

func _on_confirm_yes() -> void:
	_confirm_panel.hide()
	if _yes_callable.is_valid():
		_yes_callable.call()

func _on_confirm_no() -> void:
	_confirm_panel.hide()

# ==========================================
# UI CONSTRUCTION
# ==========================================

func _build_notification_ui() -> void:
	_notif_panel = PanelContainer.new()
	_notif_panel.custom_minimum_size = Vector2(300, 80)
	_notif_panel.position = Vector2(1920, 20) # Hidden off-screen right initially
	_notif_panel.hide()

	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.Base.PURE_BLACK
	style.border_width_left = 4
	style.border_color = UIColors.Base.CHIP_BLUE
	_notif_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	_notif_panel.add_child(vbox)

	_notif_title = Label.new()
	_notif_title.theme_type_variation = "HeaderLabel"
	vbox.add_child(_notif_title)

	_notif_msg = Label.new()
	_notif_msg.theme_type_variation = "BodyTextLabel"
	_notif_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_notif_msg)

	add_child(_notif_panel)

func _build_confirmation_ui() -> void:
	_confirm_panel = PanelContainer.new()
	_confirm_panel.custom_minimum_size = Vector2(400, 200)
	_confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	_confirm_panel.offset_top = _confirm_panel.custom_minimum_size.y / -2
	_confirm_panel.offset_right = _confirm_panel.custom_minimum_size.x / 2
	_confirm_panel.offset_bottom = _confirm_panel.custom_minimum_size.y / 2
	_confirm_panel.offset_left = _confirm_panel.custom_minimum_size.x / -2
	_confirm_panel.hide()

	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.Base.PURE_BLACK
	style.set_border_width_all(2)
	style.border_color = UIColors.Base.CHIP_BLUE
	_confirm_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	_confirm_panel.add_child(vbox)

	_confirm_title = Label.new()
	_confirm_title.theme_type_variation = "HeaderLabel"
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_confirm_title)

	_confirm_msg = Label.new()
	_confirm_msg.theme_type_variation = "BodyTextLabel"
	_confirm_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_confirm_msg)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)

	_btn_yes = Button.new()
	_btn_yes.text = "Yes"
	_btn_yes.theme_type_variation = "PrimaryActionButton"
	UIUtils.safe_connect(_btn_yes.pressed, _on_confirm_yes, "UIModalManager _btn_yes")
	hbox.add_child(_btn_yes)

	_btn_no = Button.new()
	_btn_no.text = "No"
	_btn_no.theme_type_variation = "PrimaryActionButton"
	UIUtils.safe_connect(_btn_no.pressed, _on_confirm_no, "UIModalManager _btn_no")
	hbox.add_child(_btn_no)

	add_child(_confirm_panel)
