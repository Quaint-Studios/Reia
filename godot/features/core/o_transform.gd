class_name TransformObserver
extends Observer

func watch() -> Resource:
	return C_Transform

func match() -> QueryBuilder:
	return q.with_all([C_Transform])

func on_component_added(entity: Entity, component: Resource) -> void:
	var c_tr := component as C_Transform
	@warning_ignore("unsafe_property_access")
	entity.global_position = c_tr.position

func on_component_changed(entity: Entity, _component: Resource, property: String, new_value: Variant, _old_value: Variant) -> void:
	match property:
		"position":
			print("changed to %s" % new_value)
			@warning_ignore("unsafe_property_access")
			entity.global_position = new_value
		_:
			print("changed %s and %s" % [property, new_value])

func on_component_removed(_entity: Entity, _component: Resource) -> void:
	pass
