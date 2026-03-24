class_name CombatVFXObserver extends Observer

func watch() -> Resource:
	return C_DamageEvent

func on_component_added(entity: Entity, component: Resource):
	var dmg = component as C_DamageEvent
	call_deferred("_spawn_vfx", entity.global_position, dmg.damage_type)

func _spawn_vfx(pos: Vector3, type: String):
	# var vfx = preload("res://client/assets/vfx/hit_blood.tscn").instantiate()
	# get_tree().current_scene.add_child(vfx)
	# vfx.global_position = pos
	print("VFX spawned but not created yet for type: %s" % type)
	
	# var audio_3d = AudioStreamPlayer3D.new()
	# audio_3d.stream = preload("res://client/assets/audio/sfx/combat/hit.wav")
	# audio_3d.bus = "SFX"
	# vfx.add_child(audio_3d)
	# audio_3d.play()
	print("Hit sound played but not created yet for type: %s" % type)
