extends Attackable

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visuals: Node3D = $Visuals

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera : Camera3D = $CameraPivot/Camera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(_event: InputEvent):
	if Input.is_action_just_pressed("quit"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("quit")

	if Input.is_action_just_pressed("click"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("click")

	if Input.is_action_just_pressed("attack"):
		GameUI.instance.status_bars.set_health(72, 100)
		print("attack")

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		print("Mouse Click/Unclick at: ", event.position)
		pass

	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			handle_camera(event)

func _physics_process(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		handle_inputs()

	move_and_slide()

func handle_camera(event: InputEvent):
	var cur_rot = camera_pivot.rotation
	camera_pivot.set_rotation(Vector3(cur_rot.x + -event.relative.y * 0.005, cur_rot.y + -event.relative.x * 0.005, 0))
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -(deg_to_rad(25.0)), deg_to_rad(25.0))
	camera_pivot.rotation.z = 0

	var zoom = 10
	var pos_y_formula_1 = 0.5 + ((0.5 / PI) * camera_pivot.rotation.x)
	var pos_y_formula_2 = 0.5 + ((0.5 / PI / 2) * camera_pivot.rotation.x)
	var pos_z_formula = 1.5 + ((1.5 / PI / 2) * camera_pivot.rotation.x * -zoom)
	camera.position.x = 0
	camera.position.y = pos_y_formula_2 * 2
	camera.position.y = clamp(camera.position.y, pos_y_formula_1, pos_y_formula_2)
	camera.position.z =  pos_z_formula

func handle_inputs():
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle movement.

	var input_dir = Input.get_vector("left", "right", "forward", "back")
	print("input dir: ", input_dir)
	var direction = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		visuals.look_at(position + direction)
		visuals.rotation.x = 0
		visuals.rotation.z = 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
