extends Node

var camera: CameraInput = null

func _ready() -> void:
	camera = CameraInput.new()

func _unhandled_input(event: InputEvent) -> void:
	camera.unhandled_input(event)

func _process(delta: float) -> void:
	camera.process(delta)
