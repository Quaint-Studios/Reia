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
		var hit_node := result.collider.get_parent() as Entity # The StaticBody's parent is the Entity
		if hit_node is Entity:
			var interactable := hit_node.get_component(C_Interactable) as C_Interactable
			if interactable:
				# Tell the UI to show "Bone [E to Pickup]"
				UIEventBus.world.show_interaction_prompt.emit(interactable.item_name, interactable.action_verb)

				# Listen for the E key!
				if Input.is_action_just_pressed("interact"):
					_send_pickup_request(hit_node)
				return

	# If we hit nothing, hide the prompt
	UIEventBus.world.hide_interaction_prompt.emit()

func _send_pickup_request(target_entity: Entity) -> void:
	var net_id := EntityMap.client.get_network_id(target_entity)
	var writer := StreamPeerBuffer.new()
	writer.put_u32(1) # Action ID 1 = Interact/Pickup (TODO: Enum for this)
	writer.put_64(net_id)
	NetworkRouter.client.queue_packet(0, OpCode.ID.ACTION_REQUEST, writer.data_array)
