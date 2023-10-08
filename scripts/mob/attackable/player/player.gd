class_name Player extends Attackable

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visuals: Node3D = $Visuals
@onready var camera_points : Node3D = $CameraPoints

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera : Camera3D = $CameraPivot/Camera

func set_anim(node_name: String, param_name: String):
	%AnimationTree.set("parameters/" + node_name + "/transition_request", param_name)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	%AnimationTree.active = true

func _process(_delta):
	if position.y <= -10: # handle falling off the map for now
		position.y = 1
		velocity = Vector3.ZERO
		# TODO: For some fun in the future, let's just set a max velocity on reset.
		# Then lerp or tween to it.
		# So you can still fall really fast but won't go at the speed of light
		# and break the game lol.

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		print("Mouse Click/Unclick at: ", event.position)
		pass

	if event is InputEventMouseMotion:
		pass

func _physics_process(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_inputs()

	move_and_slide()

func _handle_inputs():
	handle_attack()
	handle_movement()

func handle_movement():
	# Handle jump.
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			set_anim("in_air", "true")
			velocity.y = JUMP_VELOCITY
		else:
			set_anim("in_air", "false")

	# Get the input direction and handle movement.

	var input_dir = Input.get_vector("left", "right", "forward", "back")
	if input_dir:
		set_anim("movements", "run")
	else:
		set_anim("movements", "idle")
	var direction = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		visuals.look_at(position + direction)
		visuals.rotation.x = 0
		visuals.rotation.z = 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func handle_attack():
	if Input.is_action_just_pressed("attack"):
		# GameUI.instance.status_bars.set_health(72, 100)
		var space = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(camera.global_position,
			camera.global_position - camera.global_transform.basis.z * 100, PhysicsUtils.arr_to_collision_mask(
				[ PhysicsUtils.ENEMY_MASK ]
			))
		var collision = space.intersect_ray(query)
		if collision:
			print("Attacked:", collision.collider.name)
			_attack(collision.collider)
		else:
			print("Collide with:", "nuthin")
