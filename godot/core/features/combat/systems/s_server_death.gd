class_name ServerDeathSystem extends System
## Runs AFTER DamageCalculationSystem. Handles removing dead things and dropping loot.

func query() -> QueryBuilder:
	return q.with_all([C_Dead, C_Transform])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		if entity.has_component(C_MonsterTag):
			_drop_bone(entity)
			
		# Queue the entity for absolute deletion from the ECS World
		cmd.remove_entity(entity)
		
		# Free the visual Godot Node
		var node := entity as Node
		if node: node.queue_free()

func _drop_bone(dead_monster: Entity) -> void:
	var pos := (dead_monster.get_component(C_Transform) as C_Transform).transform.origin
	
	var bone_entity := Entity.new()
	bone_entity.add_component(C_Transform.new(Transform3D(Basis(), pos)))
	bone_entity.add_component(C_Interactable.new("Bone", ActionVerb.ID.PICKUP, OpCode.ID.PICKUP_ITEM))
	
	# Create the Visual Prism natively in Godot code (No .tscn required for simple loot!)
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.2, 0.1, 0.6) # A rectangular prism
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#E3DAC9") # Off-white bone color
	box.material = mat
	mesh_instance.mesh = box
	
	# Add collision so the client can raycast it
	var static_body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	
	static_body.add_child(col)
	bone_entity.add_child(mesh_instance)
	bone_entity.add_child(static_body)
	
	# Set physics layers for raycasting (e.g., Layer 14 is ITEM_PICKUP)
	static_body.collision_layer = 0
	static_body.set_collision_layer_value(14, true)
	
	# Spawn it into the server world
	get_tree().current_scene.add_child(bone_entity)
	cmd.add_entity(bone_entity)
