class_name PlayerMovementSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Transform, C_Velocity])

func process(entity: Entity, _delta: float) -> void:
	var velocity_comp: C_Velocity = entity.get_component(C_Velocity)
	var transform_comp: C_Transform = entity.get_component(C_Transform)

	# On the server we'd use bounding boxes for the player
	if entity is CharacterBody3D:
		var character: CharacterBody3D = entity as CharacterBody3D

		# Set velocity and move using Godot's physics API
		character.velocity = velocity_comp.velocity
		var __ := character.move_and_slide()
		# Sync ECS transform from node after movement
		transform_comp.transform.origin = character.global_position
