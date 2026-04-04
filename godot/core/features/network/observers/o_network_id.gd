class_name NetworkIdObserver extends Observer

func watch() -> Resource:
	return C_NetworkId

func on_component_added(entity: Entity, component: Resource) -> void:
	var net_id := (component as C_NetworkId).id
	EntityMap.register(net_id, entity)

func on_component_removed(_entity: Entity, component: Resource) -> void:
	var net_id := (component as C_NetworkId).id
	EntityMap.unregister(net_id)
