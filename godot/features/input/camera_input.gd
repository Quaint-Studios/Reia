class_name CameraInput

var aim: C_AimState = null

func unhandled_input(event: InputEvent) -> void:
	if aim == null:
		var player_entity := LocalCache.player_entity
		if player_entity == null:
			return
		aim = player_entity.get_component(C_AimState) as C_AimState
		if aim == null:
			return

	var camera_state := LocalCache.camera_global.camera_state

	# Toggle aim
	if Input.is_action_just_pressed("aim"):
		aim.is_aiming = not aim.is_aiming

	# Rotate camera with mouse motion
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		camera_state.target_yaw -= motion.relative.x * camera_state.yaw_sensitivity
		camera_state.target_pitch = clampf(
			camera_state.target_pitch - motion.relative.y * camera_state.pitch_sensitivity,
			camera_state.min_pitch,
			camera_state.max_pitch
		)

	# Zoom camera with mouse wheel
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var min_len := 2.0
			var max_len := 12.0
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera_state.distance = clampf(camera_state.distance - CameraStateData.ZOOM_STEP, min_len, max_len)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera_state.distance = clampf(camera_state.distance + CameraStateData.ZOOM_STEP, min_len, max_len)

func process(delta: float) -> void:
	# Sync everything
	if aim == null:
		var player_entity := LocalCache.player_entity
		if player_entity == null:
			return
		aim = player_entity.get_component(C_AimState) as C_AimState
		if aim == null:
			return

	var camera_state := LocalCache.camera_global.camera_state
	camera_state.yaw = lerp_angle(camera_state.yaw, camera_state.target_yaw, camera_state.rotation_lerp_speed * delta)
	camera_state.pitch = lerp_angle(camera_state.pitch, camera_state.target_pitch, camera_state.rotation_lerp_speed * delta)
	camera_state.fov = lerp(camera_state.fov, camera_state.target_fov, camera_state.fov_lerp_speed * delta)
