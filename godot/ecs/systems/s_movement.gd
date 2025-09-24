class_name MovementSystem
extends System

func query() -> QueryBuilder:
	# Find all entities that have both transform and velocity
	return q.with_all([C_Transform, C_Velocity])

func process(entity: Entity, delta: float) -> void:
	var transform_comp : C_Transform = entity.get_component(C_Transform)
	var velocity_comp : C_Velocity = entity.get_component(C_Velocity)

	# Move the entity based on its velocity
	transform_comp.position += velocity_comp.velocity * delta

	# Update the actual entity position in the scene
	entity.global_position = transform_comp.position

	# Bounce off screen edges (simple example)
	if transform_comp.position.x > 10 or transform_comp.position.x < -10:
		velocity_comp.velocity.x *= -1
