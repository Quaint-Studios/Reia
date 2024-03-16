class_name Fireball extends Ability

var model = load("res://scripts/mob/attackable/player/abilities/combat/pyro/fireball/Ball.glb")

func cast_on_target(player: Player, _target: Vector3):
	var start = player.visuals.get_node("female_player/Armature/Skeleton3D/RightHand")
	var new_model = model.instantiate()
	start.add_child(new_model)
	start.position = Vector3.ZERO
