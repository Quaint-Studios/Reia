@tool
class_name GhostPreviewManager
extends RefCounted

## Manages the ghost preview tracking the cursor in 3D.

var _ghost_instance: MeshInstance3D = null
var _ghost_material: StandardMaterial3D = null
var _current_shape: ShapeFlyoutContainer.PrimitiveShape = ShapeFlyoutContainer.PrimitiveShape.BOX
var _current_size: Vector3 = Vector3.ONE


func _init() -> void:
	_ghost_material = PrimitiveMeshFactory.create_ghost_material()


## Mounts the ghost instance into the active 3D world/scene without owner (never serialized).
func mount(parent_node: Node) -> void:
	if _ghost_instance == null:
		_ghost_instance = MeshInstance3D.new()
		_ghost_instance.name = "MapEditorGhostPreview"
		_ghost_instance.material_override = _ghost_material
		_ghost_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost_instance.visible = false
		_rebuild_ghost_mesh()

	if parent_node != null and _ghost_instance.get_parent() != parent_node:
		if _ghost_instance.get_parent() != null:
			_ghost_instance.get_parent().remove_child(_ghost_instance)
		parent_node.add_child(_ghost_instance)


## Updates the ghost primitive shape when the user selects a new preset in the flyout.
func set_shape(shape: ShapeFlyoutContainer.PrimitiveShape, size: Vector3 = Vector3.ONE) -> void:
	_current_shape = shape
	_current_size = size
	_rebuild_ghost_mesh()


## Positions the ghost at the snapped surface location with optional dynamic size and rotation.
func update_preview(
	snapped_ground_pos: Vector3,
	is_visible: bool,
	p_size: Vector3 = Vector3.ZERO,
	p_rot: Vector3 = Vector3.ZERO
) -> void:
	if _ghost_instance == null:
		return
	_ghost_instance.visible = is_visible
	if is_visible:
		if p_size.length_squared() > 0.001 and p_size != _current_size:
			_current_size = p_size
			_rebuild_ghost_mesh()
		_ghost_instance.rotation = p_rot
		_ghost_instance.position = snapped_ground_pos + Vector3(0.0, _current_size.y * 0.5, 0.0)


## Hides the preview immediately (e.g., when mouse leaves the viewport).
func hide() -> void:
	if _ghost_instance != null:
		_ghost_instance.visible = false


## Removes and frees the ghost instance from the scene.
func teardown() -> void:
	if _ghost_instance != null:
		if _ghost_instance.get_parent() != null:
			_ghost_instance.get_parent().remove_child(_ghost_instance)
		_ghost_instance.queue_free()
		_ghost_instance = null


func _rebuild_ghost_mesh() -> void:
	if _ghost_instance != null:
		_ghost_instance.mesh = PrimitiveMeshFactory.build_mesh(_current_shape, _current_size)
