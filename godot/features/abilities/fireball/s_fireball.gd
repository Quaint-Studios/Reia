class_name FireballSystem
extends System

const FIREBALL_RADIUS: float = 0.5
var _fireball_sphere_shape: SphereShape3D

func _init() -> void:
	_fireball_sphere_shape = SphereShape3D.new()
	_fireball_sphere_shape.radius = FIREBALL_RADIUS

func query() -> QueryBuilder:
	return q.with_all([C_Fireball, C_Node3DRef])

func process(entity: Entity, delta: float) -> void:
	var fireball: C_Fireball = entity.get_component(C_Fireball)
	var node_ref: C_Node3DRef = entity.get_component(C_Node3DRef)
	var caster_ref: C_CharacterBodyRef = fireball.caster
	var target_ref: C_Node3DRef = fireball.target
	var node: Node3D = node_ref.node
	var target := target_ref.node if target_ref else null

	if node == null or target == null:
		return

	var start_pos := fireball.start_position
	var current_pos := node.global_transform.origin

	# Calculate direction to target
	fireball.direction = (target.global_transform.origin - fireball.start_position).normalized()
	var velocity: Vector3 = fireball.direction * fireball.speed
	var next_pos: Vector3 = current_pos + velocity * delta

	node.global_transform.origin = next_pos

	# Track distance traveled
	var traveled_distance := start_pos.distance_to(next_pos)
	fireball.traveled_distance = traveled_distance

	# Fizzle out of max distance reached
	if traveled_distance >= fireball.max_distance:
		print("Fireball fizzled out after reaching max distance")
		ECS.world.remove_entity(entity)
		return

	# Sphere collision check with static geometry
	var space_state := node.get_world_3d().direct_space_state

	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _fireball_sphere_shape
	params.transform = node.global_transform
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [node, caster_ref.node]

	var collisions := space_state.intersect_shape(params, 1)
	if collisions.size() > 0:
		# On collision, apply damage/effects here
		# For now, just remove the fireball
		ECS.world.remove_entity(entity)
		return

	var target_distance := current_pos.distance_to(target.global_transform.origin)
	if target_distance <= FIREBALL_RADIUS:
		# On hit, apply damage/effects here
		print("Fireball hit the target")
		ECS.world.remove_entity(entity)
		return
