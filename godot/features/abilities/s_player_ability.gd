class_name PlayerAbilitySystem
extends System

const COMBO_RESET_TIME: float = 0.8

static var ability_cache: Dictionary = {}
static var fireballRes := preload("res://features/abilities/fireball/r_fireball_ability.gd")

func query() -> QueryBuilder:
	return q.with_all([C_PlayerAbilityState, C_LocalPlayer, C_CharacterBodyRef, C_CameraTarget])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var ability_state: C_PlayerAbilityState = entity.get_component(C_PlayerAbilityState)
		var body_ref: C_CharacterBodyRef = entity.get_component(C_CharacterBodyRef)
		var camera_target: C_CameraTarget = (entity.get_component(C_CameraTargetRef) as C_CameraTargetRef).camera_target
		var character: CharacterBody3D = body_ref.node


		# Update cooldowns and combo timers
		for i in range(ability_state.cooldowns.size()):
			if ability_state.cooldowns[i] > 0.0:
				ability_state.cooldowns[i] = max(0.0, ability_state.cooldowns[i] - delta)
			# Reset combo if too much time has passed since last cast
			if ability_state.last_cast_times[i] > 0.0 and (Time.get_ticks_msec() / 1000.0 - ability_state.last_cast_times[i]) > COMBO_RESET_TIME:
				ability_state.attack_combos[i] = 0

		# Handle queued ability
		if ability_state.queued_ability != -1:
			var ability_index: int = ability_state.queued_ability
			if ability_index >= 0 and ability_index < ability_state.cooldowns.size():
				if ability_state.cooldowns[ability_index] <= 0.0:
					var ability := fireballRes.new()
					if ability != null:
						print("PlayerAbilitySystem: Executing ability index %d, combo stage %d" % [ability_index, ability_state.attack_combos[ability_index]])

						# Raycast for target (same logic as before, now in physics tick)
						var ray_origin := character.global_transform.origin + Vector3.UP * 1.0
						var ray_dir := Vector3(0, 0, -1).rotated(Vector3.UP, camera_target.yaw)
						var ray_end := ray_origin + ray_dir * 20.0

						var ray_params := PhysicsRayQueryParameters3D.new()
						ray_params.from = ray_origin
						ray_params.to = ray_end
						ray_params.exclude = [character]
						ray_params.collide_with_areas = true
						ray_params.collide_with_bodies = true
						ray_params.collision_mask = 2 # Only collide with layer 2 (ability targets)

						print("Raycasting from %s to %s" % [ray_origin, ray_end])

						var world_3d := character.get_world_3d()
						if world_3d != null:
							var space_state := world_3d.direct_space_state
							if space_state != null:
								var result := space_state.intersect_ray(ray_params)
								if result.has("collider") && result.collider is Entity:
									var target_entity: Entity = result.collider
									print("Ability target entity found: %s" % target_entity)
									# Pass combo stage to ability execution if needed
									ability.execute(entity, target_entity)
								else:
									print("Ability target entity not found in raycast result.")

						# Update last cast time and increment combo stage
						ability_state.last_cast_times[ability_index] = Time.get_ticks_msec() / 1000.0
						ability_state.attack_combos[ability_index] += 1
						# Reset combo if max stage reached (example: 3-stage combo)
						if ability_state.attack_combos[ability_index] >= 3:
							ability_state.attack_combos[ability_index] = 0

						ability_state.cooldowns[ability_index] = (ability as Ability).cooldown
					else:
						push_error("PlayerAbilitySystem: Ability resource is null or not of type Ability.")
				else:
					push_warning("PlayerAbilitySystem: Ability on cooldown.")
			else:
				push_error("PlayerAbilitySystem: Invalid ability index queued.")
			ability_state.queued_ability = -1 # Clear the queued ability
