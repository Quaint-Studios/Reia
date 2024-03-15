class_name PlayerHUD extends MarginContainer

@export var status_bars: PlayerStatusBars
@export var interactor: InteractorUI
var is_showing_interactor := false
@export var minimap: PlayerMinimap

func _ready() -> void:
	if status_bars == null:
		status_bars = get_node("PlayerStatusBars")
	if interactor == null:
		interactor = get_node("PlayerInteractor")
	if minimap == null:
		minimap = get_node("PlayerMinimap")

func hide_all():
	status_bars.hide()
	interactor.hide()
	minimap.hide()

func reset():
	status_bars.show()
	if is_showing_interactor:
		interactor.show()
	minimap.show()

func show_interactor(_object_name: String):
	is_showing_interactor = true
	interactor.object_name.text = _object_name
	interactor.show()

func hide_interactor():
	is_showing_interactor = false
	interactor.hide()
