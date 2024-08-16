class_name PlayerUI_HUD extends Control
## Handles the status bar, interactor and minimap.

@onready var status_bars: PlayerUI_StatusBars = %StatusBars
@onready var interactor: PlayerUI_Interactor = %Interactor
var is_showing_interactor := false
@onready var minimap: PlayerUI_Minimap = %Minimap
@onready var pause_menu: PlayerUI_PauseMenu = %PauseMenu

func hide_all() -> void:
	status_bars.hide()
	interactor.hide()
	minimap.hide()

func reset() -> void:
	status_bars.show()
	if is_showing_interactor:
		interactor.show()
	minimap.show()

func show_interactor(object_name: String) -> void:
	is_showing_interactor = true
	interactor.object_name.text = object_name
	interactor.show()

func hide_interactor() -> void:
	is_showing_interactor = false
	interactor.hide()
