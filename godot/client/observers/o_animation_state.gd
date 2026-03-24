class_name AnimationStateObserver extends Observer

func watch() -> Resource:
	return C_State

func on_component_changed(entity: Entity, _comp: Resource, property: String, new_state: Variant, _old: Variant) -> void:
	if property == "current_state":
		var anim_tree: AnimationTree = entity.get_node_or_null("AnimationTree")
		if anim_tree:
			var new_anim_state: StringName = new_state
			var playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")
			playback.travel(new_anim_state)
