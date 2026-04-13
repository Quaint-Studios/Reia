extends Camera3D
## Attached to the Local Player's Camera3D

const INTERACT_RANGE = 3.0

func _physics_process(_delta: float) -> void:
	var space_state := get_world_3d().direct_space_state
	var center := get_viewport().get_visible_rect().size / 2
	var origin := project_ray_origin(center)
	var end := origin + project_ray_normal(center) * INTERACT_RANGE

	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1 << 13 # Bitmask for Layer 14 (ITEM_PICKUP)

	var result := space_state.intersect_ray(query)

	if result and result.collider:
		@warning_ignore("unsafe_cast")
		var hit_node := (result.collider as Node).get_parent() as Entity # The StaticBody's parent is the Entity
		if hit_node is Entity:
			var interactable := hit_node.get_component(C_Interactable) as C_Interactable
			if interactable:
				# Convert the hashed Enum ID back into a readable string (e.g., "PICKUP" -> "Pickup")
				# For localization, you can wrap this in tr(): tr("ACTION_" + verb_key)
				var verb_key: String = ActionVerb.ID.find_key(interactable.action_verb)
				var display_verb := verb_key.capitalize() if verb_key else "Interact"

				# Tell the UI to show "Bone [E to Pickup]"
				UIEventBus.world.show_interaction_prompt.emit(interactable.item_name, display_verb)

				if Input.is_action_just_pressed("interact"):
					_send_interaction_request(hit_node, interactable.interact_op_code)
				return

	# If we hit nothing, hide the prompt
	UIEventBus.world.hide_interaction_prompt.emit()

func _send_interaction_request(target_entity: Entity, op_code: int) -> void:
	var net_id := EntityMap.client.get_network_id(target_entity)
	var writer := StreamPeerBuffer.new()
	writer.put_64(net_id)

	# We blindly send the OpCode defined by the component.
	# Zero client-side branching.
	NetworkRouter.client.queue_packet(0, op_code, writer.data_array)
