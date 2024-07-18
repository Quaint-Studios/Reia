class_name GameManager extends Node
## This is the main game manager. It handles the game state, FPS, and window size.

static var instance: GameManager

static var state: GAME_STATES = GAME_STATES.MENU:
	set(value):
		state = value

		match value:
			GAME_STATES.PLAY:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		update_fps()
	get:
		return state
enum GAME_STATES {MENU, PLAY, PAUSE}

# Singleton
func _init():
	if instance == null:
		instance = self
	else:
		queue_free()
		free()

func _ready():
	GameManager.update_fps()
	GameManager.set_window_size()

# Handles releasing and capturing the mouse
func _input(_event: InputEvent):
	# Let the UI handle the rest
	if state != GAME_STATES.PLAY:
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
	match state:
		GAME_STATES.PLAY:
			state = GAME_STATES.PAUSE
		GAME_STATES.PAUSE:
			state = GAME_STATES.PLAY

static func update_fps():
	var max_fps = Constants.GAME_DEFAULT_FPS if state == GAME_STATES.PLAY else Constants.UI_DEFAULT_FPS
	print("FPS: ", max_fps)
	Engine.set_max_fps(max_fps)

static func set_window_size():
	DisplayServer.window_set_min_size(Vector2i(1152, 648))

static func setup_sound_manager():
	SoundManager.set_default_music_bus("Music")
	SoundManager.set_default_sound_bus("SFX")
	SoundManager.set_default_ui_sound_bus("Interface")
	SoundManager.set_default_dialogue_bus("Dialogue")

	# Temporary
	SoundManager.set_master_volume(5.0 / 100.0)
