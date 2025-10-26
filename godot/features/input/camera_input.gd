class_name CameraInput
extends Node

var _aim: C_AimState = null
var _orbit: C_CameraOrbit = null
var _col: C_CameraCollision = null

func setup(camera_entity: Camera, player_entity: Player) -> void:
	if player_entity.has_component(C_AimState):
		_aim = player_entity.get_component(C_AimState) as C_AimState
	if camera_entity.has_component(C_CameraOrbit):
		_orbit = camera_entity.get_component(C_CameraOrbit) as C_CameraOrbit
	if camera_entity.has_component(C_CameraCollision):
		_col = camera_entity.get_component(C_CameraCollision) as C_CameraCollision

func _unhandled_input(event: InputEvent) -> void:
	if _aim == null || _orbit == null || _col == null:
		return

	# Toggle aim
	if Input.is_action_just_pressed("aim"):
		_aim.is_aiming = not _aim.is_aiming

	# Rotate camera with mouse motion
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_orbit.target_yaw -= motion.relative.x * _orbit.yaw_sensitivity
		_orbit.target_pitch = clampf(_orbit.target_pitch - motion.relative.y * _orbit.pitch_sensitivity, _orbit.min_pitch, _orbit.max_pitch)

	# Zoom camera with mouse wheel
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var step := 0.5
			var min_len := 2.0
			var max_len := 12.0
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_col.base_length = clampf(_col.base_length - step, min_len, max_len)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_col.base_length = clampf(_col.base_length + step, min_len, max_len)
