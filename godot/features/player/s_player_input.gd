class_name PlayerInputSystem
extends System

const MOVE_SPEED: float = 6.0
const JUMP_SPEED: float = 4.0
const ROTATE_SPEED: float = 16.0
const LATERAL_BLEND: float = 0.3 # 0.0 = no control, 1.0 = full control

var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var preloaded_fireball_ability := preload("res://features/abilities/fireball/r_fireball_ability.gd")

func query() -> QueryBuilder:
	return q.with_all([
		C_LocalPlayer,
		C_Velocity,
		C_CharacterBodyRef,
		C_DashIntent,
		C_CameraTarget,
		C_JumpState,
		C_PlayerAbilityState
	])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var velocity_comp: C_Velocity = entity.get_component(C_Velocity)
		var body_ref: C_CharacterBodyRef = entity.get_component(C_CharacterBodyRef)
		var dash_intent: C_DashIntent = entity.get_component(C_DashIntent)
		var camera_target: C_CameraTarget = entity.get_component(C_CameraTarget)
		var jump_state: C_JumpState = entity.get_component(C_JumpState)
		var character: CharacterBody3D = body_ref.node

		var input_vector: Vector3 = Vector3.ZERO
		input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_vector.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")

		# Normalize horizontal movement for consistent speed
		var horizontal_input := input_vector.normalized() if input_vector.length() > 0.01 else Vector3.ZERO
		var move_dir := horizontal_input.rotated(Vector3.UP, camera_target.yaw)

		#region Jumping
		# Jump buffering
		if Input.is_action_just_pressed("jump"):
			jump_state.jump_buffer_timer = C_JumpState.JUMP_BUFFER_TIME

		jump_state.jump_buffer_timer = max(0.0, jump_state.jump_buffer_timer - delta)

		# Coyote time
		if character.is_on_floor():
			jump_state.coyote_timer = C_JumpState.COYOTE_TIME
		else:
			jump_state.coyote_timer = max(0.0, jump_state.coyote_timer - delta)

		# Jump logic
		var can_jump := character.is_on_floor() or jump_state.coyote_timer > 0.0
		var jump_requested := Input.is_action_just_pressed("jump") or jump_state.jump_buffer_timer > 0.0
		var jump_trigger := int(jump_requested and can_jump)

		var vertical_velocity := velocity_comp.velocity.y
		if jump_trigger:
			vertical_velocity = JUMP_SPEED
		elif character.is_on_floor():
			if vertical_velocity <= 0.0:
				vertical_velocity = 0.0
		else:
			vertical_velocity -= GRAVITY * delta

		# Clear jump buffer if jump was triggered
		jump_state.jump_buffer_timer *= 1 - jump_trigger
		jump_state.coyote_timer *= 1 - jump_trigger
		#endregion

		# Rotate player to face movement direction
		if move_dir.length() > 0.01:
			var target_rot := atan2(move_dir.x, move_dir.z)
			character.rotation.y = lerp_angle(character.rotation.y, target_rot, delta * ROTATE_SPEED)

		# Dash input (e.g., Shift or gamepad button)
		if Input.is_action_just_pressed("dash") and dash_intent.cooldown <= 0.0:
			dash_intent.triggered = true
			if move_dir.length() > 0.01:
				dash_intent.direction = horizontal_input.rotated(Vector3.UP, camera_target.yaw)
			else:
				dash_intent.direction = Vector3(0, 0, -1).rotated(Vector3.UP, camera_target.yaw)

		# If dashing, blend dash velocity with lateral input and preserve vertical velocity
		if dash_intent.dash_time_left > 0.0:
			var dash_dir: Vector3 = dash_intent.direction.normalized()
			var lateral_dir: Vector3 = horizontal_input
			var blended_dir: Vector3 = (dash_dir * (1.0 - LATERAL_BLEND)) + (lateral_dir * LATERAL_BLEND)
			blended_dir = blended_dir.normalized() * DashAbilitySystem.DASH_SPEED
			blended_dir.y = vertical_velocity
			velocity_comp.velocity = blended_dir
		else:
			var final_velocity := move_dir * MOVE_SPEED
			final_velocity.y = vertical_velocity
			velocity_comp.velocity = final_velocity

		# Ability 1: Fireball (ability_1)
		if Input.is_action_just_pressed("ability_1"):
			var ability_state: C_PlayerAbilityState = entity.get_component(C_PlayerAbilityState)
			if ability_state != null:
				ability_state.queued_ability = 0 # Fireball index

		# Ability 2: Cube Entity (ability_2)
		if Input.is_action_just_pressed("ability_2"):
			var enemy_test_tscn := preload("res://features/enemy/enemy_test/EnemyTest.tscn").instantiate()
			var e_enemy_test: Entity = enemy_test_tscn
			ECS.world.add_entity(e_enemy_test)

			var enemy_test: StaticBody3D = enemy_test_tscn
			var node3d_ref: C_Node3DRef = e_enemy_test.get_component(C_Node3DRef)
			node3d_ref.node = enemy_test
			enemy_test.global_transform.origin = character.global_transform.origin + Vector3(0, 0, -2).rotated(Vector3.UP, camera_target.yaw)

		# Mouse capture/release logic
		if Input.is_action_just_pressed("ui_focus_camera"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if Input.is_action_just_pressed("ui_release_camera"):
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
