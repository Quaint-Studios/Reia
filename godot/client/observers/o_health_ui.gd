class_name HealthUIObserver extends Observer

func watch() -> Resource:
	return C_Health

func on_component_changed(entity: Entity, component: Resource, property: String, new_val: Variant, _old_val: Variant) -> void:
	if property == "current" and entity.has_component(C_LocalPlayer):
		UIEventBus.combat.player_health_changed.emit(new_val, (component as C_Health).max_health)
