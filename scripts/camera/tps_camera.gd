extends Node3D

@export var look_point: Node3D
@export var follow_point: Node3D

@export var zoom: float = 1.0
@export var distance: Vector3 = (Vector3.BACK * 2.0) + (Vector3.UP * 0.5)
@onready var camera: Camera3D = $Camera

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta: float):
	# var tween = create_tween().bind_node(self).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	global_position = follow_point.global_position
	# tween.tween_property(self, "global_position", follow_point.global_position, 0.25)

	var old_rotation = global_rotation
	global_rotation = Vector3.ZERO # zero out

	camera.global_position = (global_position + (distance * zoom))
	camera.look_at(look_point.global_position)

	global_rotation = old_rotation


func _input(event: InputEvent):
	handle_zoom()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			set_global_rotation(Vector3(
				global_rotation.x +  -event.relative.y * 0.005,
				global_rotation.y + -event.relative.x * 0.005,
				0
			))
			rotation.x = clamp(rotation.x, -(deg_to_rad(30.0)), deg_to_rad(65.0))


func handle_zoom():
	const ZOOM_STEPS = 0.15
	const MIN_ZOOM = 0.15
	const MAX_ZOOM = 1.75
	if Input.is_action_pressed("zoom_in"):
		zoom -= ZOOM_STEPS
		zoom = clamp(zoom, MIN_ZOOM, MAX_ZOOM)

	if Input.is_action_pressed("zoom_out"):
		zoom += ZOOM_STEPS
		zoom = clamp(zoom, MIN_ZOOM, MAX_ZOOM)
