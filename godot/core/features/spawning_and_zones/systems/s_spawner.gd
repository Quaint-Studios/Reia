class_name SpawnerSystem extends System

func query():
	# Only tick spawners that are in active chunks (players are nearby)
	return q.with_all([C_SpawnPoint, C_ChunkActive])

func process(entities: Array[Entity], _components: Array, delta: float):
	for entity in entities:
		var spawner = entity.get_component(C_SpawnPoint) as C_SpawnPoint
		
		if spawner.current_active < spawner.max_active:
			spawner.timer -= delta
			if spawner.timer <= 0.0:
				var monster := ServerPrefabCache.get_headless_prefab(spawner.prefab).instantiate()
				monster.add_relationship(Relationship.new(C_SpawnedBy.new(), entity))
				
				get_tree().current_scene.add_child(monster)
				ECS.world.add_entity(monster)
				
				spawner.current_active += 1
				spawner.timer = spawner.respawn_delay
