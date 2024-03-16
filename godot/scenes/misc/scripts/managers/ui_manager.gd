class_name UIManager extends Node

signal open_ui
signal close_ui(ui: UI_TYPES)

static var instance: UIManager

static var is_ui_open := false

# TODO: Re-enable
# static var player_ui: PlayerUI

func _init():
	if instance == null:
		instance = self
	else:
		self.queue_free()

enum UI_TYPES { GAME, INVENTORY }

static func emit_open_ui(ui: UI_TYPES):
	print("open")
	UIManager.instance.close_ui.emit(ui) # Close all other UI first
	UIManager.instance.open_ui.emit()
	is_ui_open = true

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("forward"):
		UIManager.emit_open_ui(UI_TYPES.GAME)
		print("closing UI")

static func emit_close_ui():
	print("close")
	UIManager.instance.close_ui.emit()
	is_ui_open = false
