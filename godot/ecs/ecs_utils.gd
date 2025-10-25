class_name ECSUtils

static func sync_transform(entity: Entity) -> void:
	if entity.has_component(C_Transform):
		var c_trs := entity.get_component(C_Transform) as C_Transform
		@warning_ignore("unsafe_property_access")
		c_trs.position = entity.global_position

static func update_transform(entity: Entity, new_position: Vector3) -> void:
	if entity.has_component(C_Transform):
		var c_trs := entity.get_component(C_Transform) as C_Transform
		c_trs.position = new_position
		@warning_ignore("unsafe_property_access")
		entity.global_position = new_position
