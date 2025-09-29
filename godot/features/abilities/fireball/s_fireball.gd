class_name FireballSystem
extends System

const FIREBALL_RADIUS: float = 0.5

func query() -> QueryBuilder:
	return q.with_all([C_Fireball, C_Node3DRef])

func process(entity: Entity, delta: float) -> void:
	var fireball: C_Fireball = entity.get_component(C_Fireball)
	var node_ref: C_Node3DRef = entity.get_component(C_Node3DRef)
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
		entity.queue_free()
		return

	# Sphere collision check with static geometry
	var space_state := node.get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = FIREBALL_RADIUS

	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = sphere
	params.transform = node.global_transform
	params.collide_with_areas = false
	params.collide_with_bodies = true

	var collisions := space_state.intersect_shape(params, 1)
	if collisions.size() > 0:
		# On collision, apply damage/effects here
		# For now, just remove the fireball
		entity.queue_free()
		return
