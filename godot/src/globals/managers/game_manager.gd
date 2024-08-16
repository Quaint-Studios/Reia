class_name GameManager extends Node
## File: game_manager.gd | Authors: @makosai | License: AGPL-3.0
## Purpose: A Game Manager that handles the game's core setup.
##
## This is the main game manager. It handles the game state, FPS, graphics, sound, and window size.

static var instance: GameManager

## Depending on the state, the FPS changes and the mouse is captured or released.
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

## Initialize the singleton.
func _init() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()
		free()

## Initialize the game manager's FPS and window size.
func _ready() -> void:
	GameManager.update_fps()
	GameManager.set_window_size()
	GameManager.setup_sound_manager()

## Handles releasing and capturing the mouse.
func _input(_event: InputEvent) -> void:
	# Let the UI handle the rest.
	if state != GAME_STATES.PLAY:
		return

	# Release the mouse when the player presses the quit button.
	if Input.is_action_just_pressed("quit"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("quit")

	# Capture the mouse when the player clicks the game again.
	if Input.is_action_just_pressed("click"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("click")

static func toggle_pause() -> void:
	match state:
		GAME_STATES.PLAY:
			state = GAME_STATES.PAUSE
		GAME_STATES.PAUSE:
			state = GAME_STATES.PLAY

## Updates the FPS depending on the game state.
static func update_fps() -> void:
	var max_fps := Constants.GAME_DEFAULT_FPS if state == GAME_STATES.PLAY else Constants.UI_DEFAULT_FPS
	print("FPS: ", max_fps)
	Engine.set_max_fps(max_fps)


## Sets the minimum window size.
static func set_window_size() -> void:
	DisplayServer.window_set_min_size(Vector2i(1152, 648))

## Sets up the sound manager's default buses and volumes.
static func setup_sound_manager() -> void:
	SoundManager.set_default_music_bus("Music")
	SoundManager.set_default_sound_bus("SFX")
	SoundManager.set_default_ui_sound_bus("Interface")
	SoundManager.set_default_dialogue_bus("Dialogue")

	# Temporary
	SoundManager.set_master_volume(5.0 / 100.0)
