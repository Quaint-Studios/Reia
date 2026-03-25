class_name CombatVFXObserver extends Observer

func watch() -> Resource:
	return C_DamageEvent

func on_component_added(entity: Entity, component: Resource) -> void:
	var dmg := component as C_DamageEvent
	var __: Variant = call_deferred("_spawn_vfx", (entity as Node as Node3D).global_position, dmg.damage_type)

# TODO: Create these scenes for VFX
func _spawn_vfx(_pos: Vector3, type: String) -> void:
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
