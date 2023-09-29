class_name GameManager extends Node

static var current_ui: UI_TYPES = UI_TYPES.MAIN_MENU :
	set(value):
		current_ui = _on_current_ui_change(value)

		match value:
			UI_TYPES.PLAY:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		update_fps()
	get:
		return current_ui
static func _on_current_ui_change(value: UI_TYPES) -> UI_TYPES: return value
enum UI_TYPES { PLAY, PAUSE, MAIN_MENU, INVENTORY }

func _ready():
	GameManager.update_fps()
	GameManager.setup_sound_manager()

func _input(_event: InputEvent):
	# Let the UI handle the rest
	if current_ui != UI_TYPES.PLAY:
		return

	if Input.is_action_just_pressed("quit"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("quit")

	if Input.is_action_just_pressed("click"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("click")

static func toggle_pause():
	match current_ui:
		UI_TYPES.PLAY:
			current_ui = UI_TYPES.PAUSE
		UI_TYPES.PAUSE:
			current_ui = UI_TYPES.PLAY

static func update_fps():
	var max_fps = Constants.GAME_DEFAULT_FPS if current_ui == UI_TYPES.PLAY else Constants.UI_DEFAULT_FPS
	print("FPS: ", max_fps)
	Engine.set_max_fps(max_fps)

static func setup_sound_manager():
	SoundManager.set_default_music_bus("Music")
	SoundManager.set_default_sound_bus("SFX")
	SoundManager.set_default_ui_sound_bus("Interface")
	SoundManager.set_default_dialogue_bus("Dialogue")

