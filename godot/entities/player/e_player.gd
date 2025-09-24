# e_player.gd
class_name Player
extends Entity

func on_ready():
	# Sync the entity's scene position to the Transform component
	if has_component(C_Transform):
		var transform_comp = get_component(C_Transform)
		transform_comp.position = global_position
