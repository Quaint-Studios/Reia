class_name ServerPhysicsSystem extends System

func query() -> QueryBuilder:
	return q.with_all([C_Transform, C_Velocity]).with_none([C_Stunned, C_Dead])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var vel := entity.get_component(C_Velocity) as C_Velocity
		# Assuming the Entity Node extends CharacterBody3D
		var body := entity as Node as CharacterBody3D
		body.velocity = vel.direction * vel.speed
		var _collided := body.move_and_slide()


		# Sync Godot physics back to the ECS component for network broadcasting
		var c_trans := entity.get_component(C_Transform) as C_Transform
		c_trans.transform = (entity as Node as Node3D).global_transform
