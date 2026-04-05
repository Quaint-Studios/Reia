class_name InventoryUIObserver extends Observer

func watch() -> Resource:
	return C_HasItem # Relationship component

# TODO: Decide what we want to do with the relationship data.
func on_relationship_added(entity: Entity, _relationship: Relationship) -> void:
	if entity.has_component(C_LocalPlayer):
		UIEventBus.inventory.inventory_updated.emit() # Tells the UI to redraw

func on_relationship_removed(entity: Entity, _relationship: Relationship) -> void:
	if entity.has_component(C_LocalPlayer):
		UIEventBus.inventory.inventory_updated.emit()
