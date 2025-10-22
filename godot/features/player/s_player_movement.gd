class_name PlayerMovementSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Transform, C_Velocity, C_CharacterBodyRef])

# TODO: On the server we'd use bounding boxes for the player
func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var velocity_comp: C_Velocity = entity.get_component(C_Velocity)
		var transform_comp: C_Transform = entity.get_component(C_Transform)
		var body_ref: C_CharacterBodyRef = entity.get_component(C_CharacterBodyRef)
		var character: CharacterBody3D = body_ref.node

		# Set velocity and move using Godot's physics API
		character.velocity = velocity_comp.velocity
		var __ := character.move_and_slide()
		# Sync ECS transform from node after movement
		transform_comp.transform.origin = character.global_position
