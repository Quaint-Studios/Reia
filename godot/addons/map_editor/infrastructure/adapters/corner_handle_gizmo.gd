@tool
class_name CornerHandleGizmo
extends RefCounted

## Interactive 3D bounding box wireframe and 26 multi-axis handles gizmo.
## Includes:
## - 8 Corner Handles (3-axis scaling, gold cubes)
## - 6 Face Handles (1-axis push/pull, teal flat square pads)
## - 12 Edge Handles (2-axis scaling, coral spherical beads)
## Maintains strict pinned-opposite anchor invariant and grid snapping across all handles.

enum HandleType {
	CORNER,
	FACE,
	EDGE
}

const TOTAL_HANDLES: int = 26

const HANDLE_DIRECTIONS: Array[Vector3] = [
	# 0..7: 8 Corners (3-axis scale)
	Vector3(-1.0, -1.0, -1.0), # 0: Bottom-Left-Back
	Vector3(1.0, -1.0, -1.0), # 1: Bottom-Right-Back
	Vector3(-1.0, 1.0, -1.0), # 2: Top-Left-Back
	Vector3(1.0, 1.0, -1.0), # 3: Top-Right-Back
	Vector3(-1.0, -1.0, 1.0), # 4: Bottom-Left-Front
	Vector3(1.0, -1.0, 1.0), # 5: Bottom-Right-Front
	Vector3(-1.0, 1.0, 1.0), # 6: Top-Left-Front
	Vector3(1.0, 1.0, 1.0), # 7: Top-Right-Front

	# 8..13: 6 Face Centers (1-axis push/pull)
	Vector3(1.0, 0.0, 0.0), # 8: Right Face (+X)
	Vector3(-1.0, 0.0, 0.0), # 9: Left Face (-X)
	Vector3(0.0, 1.0, 0.0), # 10: Top Face (+Y)
	Vector3(0.0, -1.0, 0.0), # 11: Bottom Face (-Y)
	Vector3(0.0, 0.0, 1.0), # 12: Front Face (+Z)
	Vector3(0.0, 0.0, -1.0), # 13: Back Face (-Z)

	# 14..25: 12 Edge Centers (2-axis pull)
	# Edges along X (Y, Z fixed)
	Vector3(0.0, -1.0, -1.0), # 14: Bottom-Back Edge
	Vector3(0.0, -1.0, 1.0), # 15: Bottom-Front Edge
	Vector3(0.0, 1.0, -1.0), # 16: Top-Back Edge
	Vector3(0.0, 1.0, 1.0), # 17: Top-Front Edge
	# Edges along Y (X, Z fixed)
	Vector3(-1.0, 0.0, -1.0), # 18: Left-Back Edge
	Vector3(1.0, 0.0, -1.0), # 19: Right-Back Edge
	Vector3(-1.0, 0.0, 1.0), # 20: Left-Front Edge
	Vector3(1.0, 0.0, 1.0), # 21: Right-Front Edge
	# Edges along Z (X, Y fixed)
	Vector3(-1.0, -1.0, 0.0), # 22: Bottom-Left Edge
	Vector3(1.0, -1.0, 0.0), # 23: Bottom-Right Edge
	Vector3(-1.0, 1.0, 0.0), # 24: Top-Left Edge
	Vector3(1.0, 1.0, 0.0), # 25: Top-Right Edge
]

const EDGE_PAIRS: Array[Vector2i] = [
	# Bottom face edges (-Y)
	Vector2i(0, 1), Vector2i(1, 5), Vector2i(5, 4), Vector2i(4, 0),
	# Top face edges (+Y)
	Vector2i(2, 3), Vector2i(3, 7), Vector2i(7, 6), Vector2i(6, 2),
	# Vertical pillar edges
	Vector2i(0, 2), Vector2i(1, 3), Vector2i(5, 7), Vector2i(4, 6)
]

var _gizmo_root: Node3D = null
var _wireframe_instance: MeshInstance3D = null
var _handle_instances: Array[MeshInstance3D] = []
var _drag_preview_instance: MeshInstance3D = null

var _wireframe_material: StandardMaterial3D = null
var _corner_material: StandardMaterial3D = null
var _face_material: StandardMaterial3D = null
var _edge_material: StandardMaterial3D = null
var _handle_hover_material: StandardMaterial3D = null
var _handle_drag_material: StandardMaterial3D = null
var _preview_material: StandardMaterial3D = null

var _target_node: MapBlockoutNode3D = null
var _target_element_id: int = -1

var _current_shape_type: int = 0
var _current_pos: Vector3 = Vector3.ZERO
var _current_rot: Vector3 = Vector3.ZERO
var _current_size: Vector3 = Vector3.ONE
var _current_palette_id: int = 0

var _hovered_handle_index: int = -1
var _is_dragging: bool = false
var _drag_handle_index: int = -1
var _drag_start_pos: Vector3 = Vector3.ZERO
var _drag_start_rot: Vector3 = Vector3.ZERO
var _drag_start_size: Vector3 = Vector3.ONE
var _drag_start_shape_type: int = 0
var _drag_start_palette_id: int = 0
var _drag_opposite_local: Vector3 = Vector3.ZERO
var _drag_plane: Plane = Plane()


func _init() -> void:
	_init_materials()
	_build_scene_nodes()


func _init_materials() -> void:
	# Gold wireframe lines
	_wireframe_material = StandardMaterial3D.new()
	_wireframe_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wireframe_material.albedo_color = Color(1.0, 0.78, 0.18, 0.95)
	_wireframe_material.no_depth_test = true
	_wireframe_material.render_priority = 10

	# 8 Corners material: vibrant gold
	_corner_material = StandardMaterial3D.new()
	_corner_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_corner_material.albedo_color = Color(1.0, 0.78, 0.18, 1.0)
	_corner_material.no_depth_test = true
	_corner_material.render_priority = 11

	# 6 Faces material: electric teal
	_face_material = StandardMaterial3D.new()
	_face_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_face_material.albedo_color = Color(0.20, 0.85, 0.85, 1.0)
	_face_material.no_depth_test = true
	_face_material.render_priority = 11

	# 12 Edges material: warm coral / orange
	_edge_material = StandardMaterial3D.new()
	_edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_edge_material.albedo_color = Color(1.0, 0.55, 0.25, 1.0)
	_edge_material.no_depth_test = true
	_edge_material.render_priority = 11

	# Hovered handle material: crisp bright white
	_handle_hover_material = StandardMaterial3D.new()
	_handle_hover_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_handle_hover_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	_handle_hover_material.no_depth_test = true
	_handle_hover_material.render_priority = 13

	# Dragging handle material: electric cyan
	_handle_drag_material = StandardMaterial3D.new()
	_handle_drag_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_handle_drag_material.albedo_color = Color(0.18, 0.85, 1.0, 1.0)
	_handle_drag_material.no_depth_test = true
	_handle_drag_material.render_priority = 13

	# Ghost preview material
	_preview_material = PrimitiveMeshFactory.create_ghost_material()


func _build_scene_nodes() -> void:
	_gizmo_root = Node3D.new()
	_gizmo_root.name = "MapEditorCornerHandleGizmo"
	_gizmo_root.visible = false

	# Wireframe lines instance
	_wireframe_instance = MeshInstance3D.new()
	_wireframe_instance.name = "Wireframe"
	_wireframe_instance.material_override = _wireframe_material
	_wireframe_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_gizmo_root.add_child(_wireframe_instance)

	# Corner mesh (Cubes)
	var corner_mesh := BoxMesh.new()
	corner_mesh.size = Vector3(0.22, 0.22, 0.22)

	# Face meshes (Flat square pads oriented along face normals)
	var face_mesh_x := BoxMesh.new()
	face_mesh_x.size = Vector3(0.06, 0.28, 0.28)

	var face_mesh_y := BoxMesh.new()
	face_mesh_y.size = Vector3(0.28, 0.06, 0.28)

	var face_mesh_z := BoxMesh.new()
	face_mesh_z.size = Vector3(0.28, 0.28, 0.06)

	# Edge mesh (Spherical beads)
	var edge_mesh := SphereMesh.new()
	edge_mesh.radius = 0.09
	edge_mesh.height = 0.18

	for i in range(TOTAL_HANDLES):
		var handle_inst := MeshInstance3D.new()
		handle_inst.name = "Handle_%d" % i
		handle_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		if i < 8:
			handle_inst.mesh = corner_mesh
			handle_inst.material_override = _corner_material
		elif i < 14:
			if i == 8 or i == 9:
				handle_inst.mesh = face_mesh_x
			elif i == 10 or i == 11:
				handle_inst.mesh = face_mesh_y
			else:
				handle_inst.mesh = face_mesh_z
			handle_inst.material_override = _face_material
		else:
			handle_inst.mesh = edge_mesh
			handle_inst.material_override = _edge_material

		_gizmo_root.add_child(handle_inst)
		_handle_instances.append(handle_inst)

	# Drag preview instance
	_drag_preview_instance = MeshInstance3D.new()
	_drag_preview_instance.name = "DragPreview"
	_drag_preview_instance.material_override = _preview_material
	_drag_preview_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_drag_preview_instance.visible = false
	_gizmo_root.add_child(_drag_preview_instance)


## Mounts gizmo container into the active scene tree without owner (not serialized).
func mount(parent_node: Node) -> void:
	if _gizmo_root == null:
		return
	if parent_node != null and _gizmo_root.get_parent() != parent_node:
		if _gizmo_root.get_parent() != null:
			_gizmo_root.get_parent().remove_child(_gizmo_root)
		parent_node.add_child(_gizmo_root)


## Sets the blockout node and target element ID to bind the gizmo to.
func set_target(blockout_node: MapBlockoutNode3D, element_id: int) -> void:
	if blockout_node == null or blockout_node.blockout_data == null:
		clear_target()
		return

	var idx: int = blockout_node.blockout_data.find_element_index(element_id)
	if idx == -1:
		clear_target()
		return

	_target_node = blockout_node
	_target_element_id = element_id

	_current_shape_type = blockout_node.blockout_data.shape_types[idx]
	_current_pos = blockout_node.blockout_data.positions[idx]
	_current_rot = blockout_node.blockout_data.rotations[idx]
	_current_size = blockout_node.blockout_data.sizes[idx]
	_current_palette_id = blockout_node.blockout_data.palette_ids[idx]

	_update_visuals()
	if _gizmo_root != null:
		_gizmo_root.visible = true


## Refreshes gizmo geometry if target element was modified externally or via undo/redo.
func refresh_from_target() -> void:
	if _is_dragging:
		return
	if _target_node == null or _target_node.blockout_data == null or _target_element_id == -1:
		clear_target()
		return

	var idx: int = _target_node.blockout_data.find_element_index(_target_element_id)
	if idx == -1:
		clear_target()
		return

	_current_shape_type = _target_node.blockout_data.shape_types[idx]
	_current_pos = _target_node.blockout_data.positions[idx]
	_current_rot = _target_node.blockout_data.rotations[idx]
	_current_size = _target_node.blockout_data.sizes[idx]
	_current_palette_id = _target_node.blockout_data.palette_ids[idx]

	_update_visuals()
	if _gizmo_root != null:
		_gizmo_root.visible = true


## Clears selection target and hides gizmo.
func clear_target() -> void:
	_target_node = null
	_target_element_id = -1
	_is_dragging = false
	_hovered_handle_index = -1
	if _drag_preview_instance != null:
		_drag_preview_instance.visible = false
	_reset_handle_materials()
	if _gizmo_root != null:
		_gizmo_root.visible = false


## Returns true if an element is currently bound and valid.
func has_target() -> bool:
	return _target_node != null and _target_element_id != -1


## Returns target element ID.
func get_target_element_id() -> int:
	return _target_element_id


## Returns target blockout node.
func get_target_node() -> MapBlockoutNode3D:
	return _target_node


## Returns target shape type.
func get_target_shape_type() -> int:
	return _current_shape_type


## Returns active dragged handle index (0..25) or -1.
func get_drag_handle_index() -> int:
	return _drag_handle_index


## Returns true if user is actively dragging a handle.
func is_dragging() -> bool:
	return _is_dragging


func set_visible(p_visible: bool) -> void:
	if _gizmo_root != null:
		_gizmo_root.visible = p_visible and has_target()


func is_visible() -> bool:
	return _gizmo_root != null and _gizmo_root.visible


## Dynamically scales handles based on distance to camera for subtle, consistent screen size.
func update_camera_handles(camera: Camera3D) -> void:
	if not has_target() or camera == null:
		return

	var viewport_height: float = maxf(300.0, camera.get_viewport().get_visible_rect().size.y)
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		var s: float = maxf(0.2, (10.0 / viewport_height) * camera.size / 0.22)
		for i in range(TOTAL_HANDLES):
			_handle_instances[i].scale = Vector3.ONE * s
	else:
		var fov_rad: float = deg_to_rad(camera.fov)
		var tan_half_fov: float = tan(fov_rad * 0.5)
		for i in range(TOTAL_HANDLES):
			var handle: MeshInstance3D = _handle_instances[i]
			var cam_dist: float = camera.global_position.distance_to(handle.global_position)
			var world_height: float = 2.0 * cam_dist * tan_half_fov
			var handle_scale: float = maxf(0.2, (10.0 / viewport_height) * world_height / 0.22)
			handle.scale = Vector3.ONE * handle_scale


## Tests 2D screen distance from mouse position to 26 handles with depth prioritization.
## Returns handle index (0..25) or -1 if no handle was clicked.
func test_handle_hit(camera: Camera3D, mouse_pos: Vector2, max_screen_dist: float = 14.0) -> int:
	if not has_target() or camera == null:
		return -1

	var best_index: int = -1
	var best_dist: float = max_screen_dist
	var best_cam_dist: float = INF

	for i in range(TOTAL_HANDLES):
		var handle: MeshInstance3D = _handle_instances[i]
		var world_pos: Vector3 = handle.global_position

		if camera.is_position_behind(world_pos):
			continue

		var screen_pos: Vector2 = camera.unproject_position(world_pos)
		var dist: float = (screen_pos - mouse_pos).length()
		var cam_dist: float = camera.global_position.distance_to(world_pos)

		if dist < best_dist - 2.0:
			best_dist = dist
			best_index = i
			best_cam_dist = cam_dist
		elif dist <= best_dist + 2.0 and cam_dist < best_cam_dist:
			best_dist = dist
			best_index = i
			best_cam_dist = cam_dist

	return best_index


## Highlights hovered handle white.
func set_hovered_handle(handle_index: int) -> void:
	if _is_dragging:
		return
	if _hovered_handle_index == handle_index:
		return

	_hovered_handle_index = handle_index
	_reset_handle_materials()

	if _hovered_handle_index >= 0 and _hovered_handle_index < TOTAL_HANDLES:
		_handle_instances[_hovered_handle_index].material_override = _handle_hover_material


func _reset_handle_materials() -> void:
	for i in range(TOTAL_HANDLES):
		if _is_dragging and i == _drag_handle_index:
			_handle_instances[i].material_override = _handle_drag_material
		else:
			if i < 8:
				_handle_instances[i].material_override = _corner_material
			elif i < 14:
				_handle_instances[i].material_override = _face_material
			else:
				_handle_instances[i].material_override = _edge_material


## Returns human-readable description for handle index (e.g. "Top Face (+Y)", "Corner (+X, +Y, +Z)").
func get_handle_description(handle_index: int) -> String:
	if handle_index < 0 or handle_index >= TOTAL_HANDLES:
		return "Unknown"
	if handle_index < 8:
		var s := HANDLE_DIRECTIONS[handle_index]
		return "Corner (%+d, %+d, %+d)" % [int(s.x), int(s.y), int(s.z)]
	elif handle_index == 8:
		return "Right Face (+X)"
	elif handle_index == 9:
		return "Left Face (-X)"
	elif handle_index == 10:
		return "Top Face (+Y)"
	elif handle_index == 11:
		return "Bottom Face (-Y)"
	elif handle_index == 12:
		return "Front Face (+Z)"
	elif handle_index == 13:
		return "Back Face (-Z)"
	elif handle_index == 14:
		return "Bottom-Back Edge"
	elif handle_index == 15:
		return "Bottom-Front Edge"
	elif handle_index == 16:
		return "Top-Back Edge"
	elif handle_index == 17:
		return "Top-Front Edge"
	elif handle_index == 18:
		return "Left-Back Edge"
	elif handle_index == 19:
		return "Right-Back Edge"
	elif handle_index == 20:
		return "Left-Front Edge"
	elif handle_index == 21:
		return "Right-Front Edge"
	elif handle_index == 22:
		return "Bottom-Left Edge"
	elif handle_index == 23:
		return "Bottom-Right Edge"
	elif handle_index == 24:
		return "Top-Left Edge"
	elif handle_index == 25:
		return "Top-Right Edge"
	return "Handle %d" % handle_index


## Begins dragging a handle (Corner, Face, or Edge).
func begin_drag(handle_index: int, camera: Camera3D, _mouse_pos: Vector2) -> bool:
	if not has_target() or handle_index < 0 or handle_index >= TOTAL_HANDLES:
		return false
	if camera == null:
		return false

	_is_dragging = true
	_drag_handle_index = handle_index
	_hovered_handle_index = handle_index

	_drag_start_pos = _current_pos
	_drag_start_rot = _current_rot
	_drag_start_size = _current_size
	_drag_start_shape_type = _current_shape_type
	_drag_start_palette_id = _current_palette_id

	var basis := Basis.from_euler(_drag_start_rot)
	var sign_vec: Vector3 = HANDLE_DIRECTIONS[handle_index]

	# Compute pinned opposite anchor in local space:
	# Non-zero axes pin the opposite side; zero axes remain centered.
	_drag_opposite_local = Vector3.ZERO
	for k in range(3):
		if sign_vec[k] != 0.0:
			_drag_opposite_local[k] = - sign_vec[k] * (_drag_start_size[k] * 0.5)
		else:
			_drag_opposite_local[k] = 0.0

	# Initial handle world position
	var initial_handle_world: Vector3 = _drag_start_pos + (basis * (sign_vec * (_drag_start_size * 0.5)))
	if _target_node != null:
		initial_handle_world = _target_node.global_transform * initial_handle_world

	# Drag plane facing camera, passing through initial handle world position
	var plane_normal: Vector3 = - camera.global_transform.basis.z.normalized()
	_drag_plane = Plane(plane_normal, initial_handle_world)

	_reset_handle_materials()

	# Show preview mesh
	if _drag_preview_instance != null:
		_drag_preview_instance.mesh = PrimitiveMeshFactory.build_mesh(
			_drag_start_shape_type as ShapeFlyoutContainer.PrimitiveShape,
			_current_size
		)
		_drag_preview_instance.visible = true

	return true


## Updates dragged handle, maintaining pinned opposite anchor invariant and locking inactive axes.
func update_drag(camera: Camera3D, mouse_pos: Vector2, snap_enabled: bool, snap_size: float) -> void:
	if not _is_dragging or camera == null:
		return

	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = camera.project_ray_normal(mouse_pos)

	var hit_var: Variant = _drag_plane.intersects_ray(ray_origin, ray_normal)
	if hit_var == null:
		return
	var hit: Vector3 = hit_var as Vector3

	# Transform hit from world space into MapBlockoutNode3D space, then element local space
	var blockout_xform := _target_node.global_transform if _target_node != null else Transform3D.IDENTITY
	var blockout_local_hit: Vector3 = blockout_xform.affine_inverse() * hit

	var basis := Basis.from_euler(_drag_start_rot)
	var inv_basis := basis.inverse()
	var local_hit: Vector3 = inv_basis * (blockout_local_hit - _drag_start_pos)

	var sign_vec: Vector3 = HANDLE_DIRECTIONS[_drag_handle_index]
	var step: float = maxf(0.125, snap_size) if snap_enabled and snap_size > 0.0 else 0.0

	var new_size := Vector3.ZERO
	var new_local_center := Vector3.ZERO

	for k in range(3):
		if sign_vec[k] != 0.0:
			var delta_k: float = sign_vec[k] * (local_hit[k] - _drag_opposite_local[k])
			if step > 0.0:
				new_size[k] = maxf(step, roundf(delta_k / step) * step)
			else:
				new_size[k] = maxf(0.125, delta_k)
			new_local_center[k] = _drag_opposite_local[k] + (sign_vec[k] * (new_size[k] * 0.5))
		else:
			new_size[k] = _drag_start_size[k]
			new_local_center[k] = 0.0

	# For symmetric shapes (Cylinder, Sphere, Capsule):
	# If scaling X or Z (Side Face, Corner, or Edge with X/Z), link X and Z to maintain uniform circular cross-section.
	# If scaling Top/Bottom Face (+Y, -Y), only Y changes, so X and Z are untouched.
	match _drag_start_shape_type:
		ShapeFlyoutContainer.PrimitiveShape.CYLINDER, ShapeFlyoutContainer.PrimitiveShape.SPHERE, ShapeFlyoutContainer.PrimitiveShape.CAPSULE:
			if sign_vec.x != 0.0 or sign_vec.z != 0.0:
				var max_xz: float = maxf(new_size.x, new_size.z)
				new_size.x = max_xz
				new_size.z = max_xz

	var new_pos: Vector3 = _drag_start_pos + (basis * new_local_center)

	_current_pos = new_pos
	_current_size = new_size

	_update_visuals()

	# Update preview mesh
	if _drag_preview_instance != null:
		_drag_preview_instance.mesh = PrimitiveMeshFactory.build_mesh(
			_drag_start_shape_type as ShapeFlyoutContainer.PrimitiveShape,
			_current_size
		)


## Finishes drag and returns modification payload dictionary.
func end_drag() -> Dictionary:
	if not _is_dragging:
		return {}

	_is_dragging = false
	if _drag_preview_instance != null:
		_drag_preview_instance.visible = false

	_reset_handle_materials()

	return {
		"element_id": _target_element_id,
		"start_pos": _drag_start_pos,
		"start_rot": _drag_start_rot,
		"start_size": _drag_start_size,
		"final_pos": _current_pos,
		"final_rot": _current_rot,
		"final_size": _current_size,
		"palette_id": _current_palette_id
	}


## Cancels drag and reverts to initial dimensions.
func cancel_drag() -> void:
	if not _is_dragging:
		return

	_is_dragging = false
	if _drag_preview_instance != null:
		_drag_preview_instance.visible = false

	_current_pos = _drag_start_pos
	_current_rot = _drag_start_rot
	_current_size = _drag_start_size

	_reset_handle_materials()
	_update_visuals()


## Rebuilds wireframe lines and updates all 26 handle transforms in gizmo local space.
func _update_visuals() -> void:
	if _gizmo_root == null:
		return

	var blockout_xform := _target_node.global_transform if _target_node != null else Transform3D.IDENTITY
	_gizmo_root.transform = blockout_xform * Transform3D(Basis.from_euler(_current_rot), _current_pos)

	var half_size: Vector3 = _current_size * 0.5

	# Update all 26 handle positions in local space
	for i in range(TOTAL_HANDLES):
		var sign_vec: Vector3 = HANDLE_DIRECTIONS[i]
		var handle_local_pos: Vector3 = sign_vec * half_size
		if i < _handle_instances.size():
			_handle_instances[i].position = handle_local_pos

	# Rebuild wireframe lines using the 8 corners (indices 0..7)
	var lines := PackedVector3Array()
	lines.resize(EDGE_PAIRS.size() * 2)
	for e in range(EDGE_PAIRS.size()):
		var c0: Vector3 = HANDLE_DIRECTIONS[EDGE_PAIRS[e].x] * half_size
		var c1: Vector3 = HANDLE_DIRECTIONS[EDGE_PAIRS[e].y] * half_size
		lines[e * 2] = c0
		lines[e * 2 + 1] = c1

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = lines

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	_wireframe_instance.mesh = mesh


## Removes and frees all gizmo nodes.
func teardown() -> void:
	clear_target()
	if _gizmo_root != null:
		if _gizmo_root.get_parent() != null:
			_gizmo_root.get_parent().remove_child(_gizmo_root)
		_gizmo_root.queue_free()
		_gizmo_root = null
	_handle_instances.clear()
	_wireframe_instance = null
	_drag_preview_instance = null
