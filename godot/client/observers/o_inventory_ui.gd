class_name InventoryUIObserver extends Observer

func watch() -> Resource:
	return C_HasItem # Relationship component

func on_relationship_added(entity: Entity, relationship: Relationship):
	if entity.has_component(C_LocalPlayer):
		UIEventBus.inventory_updated.emit() # Tells the UI to redraw

func on_relationship_removed(entity: Entity, relationship: Relationship):
	if entity.has_component(C_LocalPlayer):
		UIEventBus.inventory_updated.emit()
