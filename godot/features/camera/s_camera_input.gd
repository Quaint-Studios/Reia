class_name CameraInputSystem
extends System

var look_delta: Vector2 = Vector2.ZERO
var zoom_delta: float = 0.0

var aim_state: C_AimState = null
var camera_orbit: C_CameraOrbit = null
var camera_mode: C_CameraMode = null

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

func _process(_delta: float) -> void:
	if aim_state == null and not find_aim_state():
		return

	if (camera_orbit == null or camera_mode == null) and not find_camera_components():
		return

	# Apply look input (orbit camera)
	aim_state.yaw -= look_delta.x * camera_orbit.yaw_sensitivity
	aim_state.pitch = clampf(
		aim_state.pitch + look_delta.y * camera_orbit.pitch_sensitivity,
		camera_orbit.min_pitch,
		camera_orbit.max_pitch
	)
	camera_orbit.target_yaw = aim_state.yaw
	camera_orbit.target_pitch = aim_state.pitch
	look_delta = Vector2.ZERO

	# Apply zoom input
	if zoom_delta != 0.0:
		camera_orbit.distance = clampf(
			camera_orbit.distance + camera_orbit.zoom_step * zoom_delta,
			camera_orbit.min_zoom,
			camera_orbit.max_zoom
		)
		zoom_delta = 0.0

func find_camera_components() -> bool:
	var entity: Entity = ECS.world.query.with_all([C_Camera, C_CameraOrbit, C_CameraMode]).execute_one()
	camera_orbit = entity.get_component(C_CameraOrbit) as C_CameraOrbit
	camera_mode = entity.get_component(C_CameraMode) as C_CameraMode
	return camera_orbit != null and camera_mode != null

func find_aim_state() -> bool:
	var entity: Entity = ECS.world.query.with_all([C_AimState]).execute_one()
	aim_state = entity.get_component(C_AimState) as C_AimState
	return aim_state != null
