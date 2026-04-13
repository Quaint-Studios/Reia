class_name TitleScreen extends Control

enum State {MAIN_MENU, PLAY_MENU}
var current_state: State = State.MAIN_MENU

@onready var main_menu_container: Control = $ScreenContainer/FlowStates/MainMenu
@onready var play_menu_container: Control = $ScreenContainer/FlowStates/PlayMenu

# Main Menu Buttons
@onready var btn_main_play: Button = %BtnMainPlay
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit

# Play Menu Elements
@onready var btn_singleplayer: Button = %BtnSingleplayer
@onready var input_username: LineEdit = %InputUsername
@onready var input_password: LineEdit = %InputPassword
@onready var btn_play_online: Button = %BtnPlayOnline
@onready var btn_host_play: Button = %BtnHostPlay
@onready var btn_host_only: Button = %BtnHostOnly

func _ready() -> void:
	_switch_to_state(State.MAIN_MENU, false)

	# Load saved username
	input_username.text = UserPreferences.get_username()

	# Wire Main Menu
	UIUtils.safe_connect(btn_main_play.pressed, _on_main_play_clicked, "TitleScreen btn_main_play")
	UIUtils.safe_connect(btn_settings.pressed, _on_settings_clicked, "TitleScreen btn_settings")
	UIUtils.safe_connect(btn_quit.pressed, _on_quit_clicked, "TitleScreen btn_quit")

	# Wire Play Menu
	UIUtils.safe_connect(btn_singleplayer.pressed, _on_play_solo, "TitleScreen btn_singleplayer")
	UIUtils.safe_connect(btn_play_online.pressed, _on_play_online, "TitleScreen btn_play_online")
	UIUtils.safe_connect(btn_host_play.pressed, _on_host_play, "TitleScreen btn_host_play")
	UIUtils.safe_connect(btn_host_only.pressed, _on_host_only, "TitleScreen btn_host_only")

# --- MAIN MENU LOGIC ---

func _on_main_play_clicked() -> void:
	_switch_to_state(State.PLAY_MENU)

func _on_settings_clicked() -> void:
	UIModalManager.show_notification("Coming Soon!", "The settings feature isn't implemented yet but it will be soon.")

func _on_quit_clicked() -> void:
	UIModalManager.ask_confirmation("Confirmation", "Are you sure you want to close the game?", _execute_quit)

func _execute_quit() -> void:
	get_tree().quit()

# --- PLAY MENU LOGIC ---

func _on_play_solo() -> void:
	_save_username_and_route()
	UIEventBus.session.intent_play_solo.emit()

func _on_play_online() -> void:
	_save_username_and_route()
	var target_ip := "127.0.0.1"
	UIEventBus.session.intent_play_online.emit(target_ip, 7777)

func _on_host_play() -> void:
	_save_username_and_route()
	UIEventBus.session.intent_host_and_play.emit(7777)

func _on_host_only() -> void:
	UIEventBus.session.intent_host_only.emit(7777)

func _save_username_and_route() -> void:
	var user := input_username.text.strip_edges()
	if user.is_empty(): user = "Adventurer"
	UserPreferences.save_username(user)

# --- VISUAL STATE ---

func _switch_to_state(new_state: State, animate: bool = true) -> void:
	current_state = new_state

	var containers: Array[Control] = [main_menu_container, play_menu_container]
	for c in containers:
		if c.visible and animate:
			_fade_out(c)
		else:
			c.hide()

	var target: Control = main_menu_container if current_state == State.MAIN_MENU else play_menu_container

	if animate: _fade_in(target)
	else: target.show()

func _fade_out(node: Control) -> void:
	var t := create_tween()
	var _tween_prop := t.tween_property(node, "modulate:a", 0.0, 0.2)
	var _callback := t.tween_callback(node.hide)

func _fade_in(node: Control) -> void:
	node.show()
	node.modulate.a = 0.0
	var t := create_tween()
	var _tween_prop := t.tween_property(node, "modulate:a", 1.0, 0.2)
