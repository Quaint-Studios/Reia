class_name CameraInputSystem
extends System

const SENSITIVITY: float = 0.012

func query() -> QueryBuilder:
	return q.with_all([C_CameraTarget])

func process(entity: Entity, delta: float) -> void:
	var camera_target: C_CameraTarget = entity.get_component(C_CameraTarget)
	
	# Mouse input (orbit)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_delta: Vector2 = Input.get_last_mouse_velocity()
		camera_target.yaw -= mouse_delta.x * SENSITIVITY * delta
		camera_target.pitch = clamp(
			camera_target.pitch - mouse_delta.y * SENSITIVITY * delta,
			camera_target.min_pitch,
			camera_target.max_pitch
		)
	
	# Gamepad right stick
	var stick_x := Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left")
	var stick_y := Input.get_action_strength("camera_up") - Input.get_action_strength("camera_down")
	if abs(stick_x) > 0.01 or abs(stick_y) > 0.01:
		camera_target.yaw -= stick_x * SENSITIVITY * delta * 10.0
		camera_target.pitch = clamp(
			camera_target.pitch - stick_y * SENSITIVITY * delta * 10.0,
			camera_target.min_pitch,
			camera_target.max_pitch
		)
