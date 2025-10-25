class_name PlayerCamera
extends Camera3D

@export var target_path: NodePath
@export var look_point_offset: Vector3 = Vector3(0, 1.5, 0)
@export var distance: float = 6.0
@export var min_distance: float = 2.0
@export var max_distance: float = 12.0
@export var min_pitch: float = -0.4
@export var max_pitch: float = 1.2
@export var mouse_sensitivity: float = 0.01
@export var zoom_step: float = 0.5

var target: Node3D = null
var yaw: float = 0.0
var pitch: float = 0.2
var _look_delta: Vector2 = Vector2.ZERO

func _ready() -> void:
	target = _resolve_target()

func _physics_process(_delta: float) -> void:
	if target == null:
		target = _resolve_target()
		if target == null:
			return
	_apply_look()
	_update_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_look_delta += motion.relative
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			distance = max(min_distance, distance - zoom_step)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			distance = min(max_distance, distance + zoom_step)

func set_target(node: Node3D) -> void:
	target = node

func _resolve_target() -> Node3D:
	if target:
		return target
	if target_path.is_empty():
		return null
	return get_node_or_null(target_path) as Node3D

func _apply_look() -> void:
	if _look_delta == Vector2.ZERO:
		return
	yaw -= _look_delta.x * mouse_sensitivity
	pitch = clamp(pitch - _look_delta.y * mouse_sensitivity, min_pitch, max_pitch)
	_look_delta = Vector2.ZERO

func _update_position() -> void:
	distance = clamp(distance, min_distance, max_distance)
	var focus := target.global_transform.origin + look_point_offset
	var rotation_basis := Basis.IDENTITY
	rotation_basis = rotation_basis.rotated(Vector3.UP, yaw)
	rotation_basis = rotation_basis.rotated(rotation_basis.x, pitch)
	var offset := rotation_basis * Vector3(0.0, 0.0, -distance)
	var desired_position := focus + offset
	global_transform.origin = desired_position
	look_at(focus, Vector3.UP)
