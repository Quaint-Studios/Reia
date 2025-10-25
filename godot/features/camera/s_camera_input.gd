class_name CameraInputSystem
extends System

var look_delta: Vector2 = Vector2.ZERO
var zoom_delta: float = 0.0

func query() -> QueryBuilder:
	return q.with_all([C_LocalPlayer, C_AimState, C_CameraState]).iterate([C_AimState, C_CameraState])

func _unhandled_input(event: InputEvent) -> void:
	# Accumulate input for next process()
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_event := event as InputEventMouseMotion
		look_delta += mouse_event.relative
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			zoom_delta -= 1.0
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			zoom_delta += 1.0

func process(entities: Array[Entity], components: Array[Array], _delta: float) -> void:
	var aims := components[0] as Array
	var cams := components[1] as Array

	for i in range(entities.size()):
		var aim: C_AimState = aims[i]
		var cam: C_CameraState = cams[i]

		# Apply look input (orbit camera)
		aim.yaw -= look_delta.x * cam.mouse_sensitivity
		aim.pitch = clampf(aim.pitch + look_delta.y * cam.mouse_sensitivity, cam.min_pitch, cam.max_pitch)
		look_delta = Vector2.ZERO

		# Apply zoom input
		if zoom_delta != 0.0:
			cam.zoom = clampf(cam.zoom + cam.zoom_step * zoom_delta, cam.min_zoom, cam.max_zoom)
			zoom_delta = 0.0
