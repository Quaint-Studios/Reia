class_name NetworkIdObserver extends Observer

## The specific EntityMap namespace (server or client) this observer updates.
var _map: EntityMap.EntityMapNamespace

func _init(map_namespace: EntityMap.EntityMapNamespace) -> void:
	_map = map_namespace

func watch() -> Resource:
	return C_NetworkId

func on_component_added(entity: Entity, component: Resource) -> void:
	if not _map: return

	var net_id := (component as C_NetworkId).id
	_map.register(net_id, entity)

func on_component_removed(_entity: Entity, component: Resource) -> void:
	if not _map: return

	var net_id := (component as C_NetworkId).id
	_map.unregister(net_id)
