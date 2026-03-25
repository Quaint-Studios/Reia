class_name MonsterAISystem extends System

func query():
	return q.with_all([C_MonsterTag, C_Transform, C_Velocity]).with_none([C_Dead, C_Stunned])

func process(entities: Array[Entity], _components: Array, _delta: float):
	var players = ECS.world.query.with_all([C_PlayerTag, C_Transform]).execute()
	
	for entity in entities:
		var monster_pos = entity.get_component(C_Transform).transform.origin
		var vel = entity.get_component(C_Velocity) as C_Velocity
		
		# Basic Aggro Logic: Find closest player within 15 meters
		var target_dir = Vector3.ZERO
		for player in players:
			var player_pos = player.get_component(C_Transform).transform.origin
			if monster_pos.distance_to(player_pos) < 15.0:
				target_dir = monster_pos.direction_to(player_pos)
				break
				
		vel.direction = target_dir # Updates the velocity for the PhysicsSystem
