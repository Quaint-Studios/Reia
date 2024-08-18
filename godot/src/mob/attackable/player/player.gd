@tool class_name Player extends Attackable

@export var inventory := PlayerInventory.new(true)
@export var abilities := AbilityManager.new().debug_create()
var map_name := SceneSelector.Maps.JADEWATER_FALLS

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visuals: Node3D = $Visuals
@onready var camera_points: Node3D = $CameraPoints

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera

var paused := false:
	set(value):
		if is_node_ready() && %PauseMenu != null:
			(%PauseMenu as Control).visible = value
		paused = value

func _ready() -> void:
	add_to_group("player")

	if !stats is PlayerStats:
		print_debug("Bug: The stats of %s is not of type PlayerStats" % name)
		# TODO: Handle conversion in the future.

	if not Engine.is_editor_hint():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		(%AnimationTree as AnimationTree).active = true

func _exit_tree() -> void:
	if !Engine.is_editor_hint() && PlayerManager.instance.player == self:
		PlayerManager.instance.player = null

func should_move() -> bool:
	if PlayerManager.instance == null:
		return false

	return PlayerManager.instance.player == self

func _process(_delta: float) -> void:
	if !should_move():
		return

	if position.y <= -10: # handle falling off the map for now
		position.y = 1
		velocity = Vector3.ZERO
		# TODO: For some fun in the future, let's just set a max velocity on reset.
		# Then lerp or tween to it.
		# So you can still fall really fast but won't go at the speed of light
		# and break the game lol.

func _unhandled_input(event: InputEvent):
	if !should_move():
		return

	if event is InputEventMouseButton:
		print("Mouse Click/Unclick at: ", event.position)
		pass

	if event is InputEventMouseMotion:
		pass

@rpc("any_peer", "call_local")
func _movement_test():
	# Call the movement on the server.
	# Server sends it to all others peers.
	# Other peers verifies it's only coming from the server.
	pass

func _physics_process(delta: float):
	if !should_move():
		return

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_inputs(delta)

	move_and_slide()

func _handle_inputs(delta: float):
	handle_attack()
	handle_skills()
	handle_movement(delta)

###
### Movement
###
func handle_movement(delta: float):
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
	var direction := (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		var old_rot = visuals.rotation

		visuals.look_at(position + direction)
		visuals.rotation.x = 0
		visuals.rotation.z = 0

		var new_rot = visuals.rotation

		visuals.rotation.y = lerp_angle(old_rot.y, new_rot.y, sin(delta * 20))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

###
### Animator
###
func set_anim(node_name: String, param_name: String):
	%AnimationTree.set("parameters/" + node_name + "/transition_request", param_name)

###
### Combat
###
func handle_attack() -> void:
	if Input.is_action_just_pressed("attack"):
		UIManager.instance.player.hud.status_bars.set_health(72, 100)
		var space := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(camera.global_position,
			camera.global_position - camera.global_transform.basis.z * 100, PhysicsUtils.arr_to_collision_mask(
				[PhysicsUtils.ENEMY_MASK]
			))
		var collision := space.intersect_ray(query)
		if collision:
			if collision.collider is Attackable:
				print("Attacked:", collision.collider.name)
				attack(collision.collider)
				return
		print("Collide with:", "nuthin")

func handle_skills() -> void:
	if Input.is_action_just_pressed("skill_2"):
		var space := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(camera.global_position,
			camera.global_position - camera.global_transform.basis.z * 100, PhysicsUtils.arr_to_collision_mask(
				[PhysicsUtils.ENEMY_MASK]
			))
		var collision := space.intersect_ray(query)
		if collision:
			print("Casted on:", collision.collider.name)
			abilities.skill_2.cast_on_target(self, collision.collider.position)
		else:
			print("Collide with:", "nuthin")

func toJSON() -> Dictionary:
	return {
		"version": 1,
		"name": name,
		"global_position": global_position,
		"global_rotation": global_rotation,
		"map_name": SceneSelector.Maps.keys()[map_name],
		"inventory": inventory.toJSON()
	}
