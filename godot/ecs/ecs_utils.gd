class_name ECSUtils

static func sync_transform(entity: Entity) -> void:
	if entity.has_component(C_Transform):
		var transform_comp: C_Transform = entity.get_component(C_Transform)
		transform_comp.transform = entity.global_transform

static func sync_component_to_transform(entity: Entity) -> void:
	if entity.has_component(C_Transform):
		var transform_comp: C_Transform = entity.get_component(C_Transform)
		entity.global_transform = transform_comp.transform
