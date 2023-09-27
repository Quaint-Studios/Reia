class_name GameManager extends Node

static var is_paused = false
static var is_in_ui = true

func _ready():
	GameManager.update_fps()
	GameManager.setup_sound_manager()

static func toggle_pause():
	is_paused = !is_paused
	update_fps()

static func toggle_is_in_ui():
	is_in_ui = !is_in_ui
	update_fps()

static func update_fps():
	var max_fps = Constants.UI.DEFAULT_FPS if is_paused or is_in_ui else Constants.Game.DEFAULT_FPS
	Engine.set_max_fps(max_fps)

static func setup_sound_manager():
	SoundManager.set_default_music_bus("Music")
	SoundManager.set_default_sound_bus("SFX")
	SoundManager.set_default_ui_sound_bus("Interface")
	SoundManager.set_default_dialogue_bus("Dialogue")
