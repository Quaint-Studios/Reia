class_name NameplateObserver extends Observer
## Automatically attaches a floating 3D text label above any entity with a username

func watch() -> Resource:
	return C_Username

func on_component_added(entity: Entity, component: Resource) -> void:
	var comp := component as C_Username
	var node3d := entity as Node as Node3D
	if not node3d: return
	
	var label := Label3D.new()
	label.text = comp.username
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.2, 0) # 2.2 meters above the origin
	label.font_size = 48
	label.outline_size = 12
	
	if entity.has_component(C_LocalPlayer):
		label.modulate = UIColors.Base.SUCCESS_GREEN # You are green!
		
	node3d.add_child(label)
