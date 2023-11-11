class_name Interactor extends RayCast3D

func _process(delta: float) -> void:
	var coll := get_collider() as Interactable

	if is_colliding():
		if coll.is_in_group("interactable"):
			UIManager.show_interaction(coll.name)
