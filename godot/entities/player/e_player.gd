class_name Player
extends Entity

func on_ready() -> void:
	# Position player, you can't get the component before it's added to the world
	var transform_comp: C_Transform = self.get_component(C_Transform)

	# Manipulate the transform component directly
	transform_comp.transform.origin = Vector3(-5, 1, -5)

	# Sync the component back to the node if it's not already being synced by a system
	ECSUtils.sync_component_to_transform(self)
