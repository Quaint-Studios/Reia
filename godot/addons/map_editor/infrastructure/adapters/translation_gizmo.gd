@tool
class_name TranslationGizmo
extends RefCounted

## Interactive 3D translation gizmo rendering 3 axis arrows (X, Y, Z) and 3 planar quads (XY, XZ, YZ).

enum Handle {
	AXIS_X = 0,
	AXIS_Y = 1,
	AXIS_Z = 2,
	PLANE_XY = 3,
	PLANE_XZ = 4,
	PLANE_YZ = 5,
	NONE = -1
}

const TOTAL_HANDLES: int = 6

var _gizmo_root: Node3D = null
var _handles_container: Node3D = null
var _arrow_instances: Array[Node3D] = []
var _plane_instances: Array[MeshInstance3D] = []
var _guideline_instance: MeshInstance3D = null
var _wireframe_instance: MeshInstance3D = null

# Materials
var _mat_x: StandardMaterial3D = null
var _mat_y: StandardMaterial3D = null
var _mat_z: StandardMaterial3D = null
var _mat_plane_xy: StandardMaterial3D = null
var _mat_plane_xz: StandardMaterial3D = null
var _mat_plane_yz: StandardMaterial3D = null
var _mat_hover: StandardMaterial3D = null
var _mat_drag: StandardMaterial3D = null
var _mat_guideline: StandardMaterial3D = null
var _mat_wireframe: StandardMaterial3D = null

# Target bindings
var _target_node: MapBlockoutNode3D = null
var _target_element_id: int = -1
var _current_pos: Vector3 = Vector3.ZERO
var _current_rot: Vector3 = Vector3.ZERO
var _current_size: Vector3 = Vector3.ONE
var _current_palette_id: int = 0
var _current_shape_type: int = 0

# Interactive state
var _hovered_handle: int = Handle.NONE
var _is_dragging: bool = false
var _drag_handle: int = Handle.NONE
var _drag_start_pos: Vector3 = Vector3.ZERO
var _drag_plane: Plane = Plane()
var _drag_hit_offset: Vector3 = Vector3.ZERO
var _cached_camera_scale: float = 1.0


func _init() -> void:
	_init_materials()
	_build_scene_nodes()


func _init_materials() -> void:
	# X Axis: Red
	_mat_x = StandardMaterial3D.new()
	_mat_x.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_x.albedo_color = Color(0.88, 0.19, 0.19, 1.0)
	_mat_x.no_depth_test = true
	_mat_x.render_priority = 15

	# Y Axis: Green
	_mat_y = StandardMaterial3D.new()
	_mat_y.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_y.albedo_color = Color(0.18, 0.62, 0.27, 1.0)
	_mat_y.no_depth_test = true
	_mat_y.render_priority = 15

	# Z Axis: Blue
	_mat_z = StandardMaterial3D.new()
	_mat_z.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_z.albedo_color = Color(0.10, 0.44, 0.76, 1.0)
	_mat_z.no_depth_test = true
	_mat_z.render_priority = 15

	# XY Plane (Locks Z): Blue translucent
	_mat_plane_xy = StandardMaterial3D.new()
	_mat_plane_xy.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_plane_xy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_plane_xy.albedo_color = Color(0.10, 0.44, 0.76, 0.45)
	_mat_plane_xy.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_plane_xy.no_depth_test = true
	_mat_plane_xy.render_priority = 14

	# XZ Plane (Locks Y): Green translucent
	_mat_plane_xz = StandardMaterial3D.new()
	_mat_plane_xz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_plane_xz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_plane_xz.albedo_color = Color(0.18, 0.62, 0.27, 0.45)
	_mat_plane_xz.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_plane_xz.no_depth_test = true
	_mat_plane_xz.render_priority = 14

	# YZ Plane (Locks X): Red translucent
	_mat_plane_yz = StandardMaterial3D.new()
	_mat_plane_yz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_plane_yz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_plane_yz.albedo_color = Color(0.88, 0.19, 0.19, 0.45)
	_mat_plane_yz.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_plane_yz.no_depth_test = true
	_mat_plane_yz.render_priority = 14

	# Hover: Bright yellow
	_mat_hover = StandardMaterial3D.new()
	_mat_hover.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_hover.albedo_color = Color(1.0, 0.92, 0.23, 1.0)
	_mat_hover.no_depth_test = true
	_mat_hover.render_priority = 16

	# Drag: Electric cyan
	_mat_drag = StandardMaterial3D.new()
	_mat_drag.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_drag.albedo_color = Color(0.18, 0.85, 1.0, 1.0)
	_mat_drag.no_depth_test = true
	_mat_drag.render_priority = 17

	# Guideline: Unshaded line
	_mat_guideline = StandardMaterial3D.new()
	_mat_guideline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_guideline.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	_mat_guideline.no_depth_test = true
	_mat_guideline.render_priority = 12

	# Wireframe Preview: Bright cyan
	_mat_wireframe = StandardMaterial3D.new()
	_mat_wireframe.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_wireframe.albedo_color = Color(0.2, 0.85, 1.0, 1.0)
	_mat_wireframe.no_depth_test = true
	_mat_wireframe.render_priority = 20


func _build_scene_nodes() -> void:
	_gizmo_root = Node3D.new()
	_gizmo_root.name = "MapEditorTranslationGizmo"
	_gizmo_root.visible = false

	# Container for handles that scales with camera distance
	_handles_container = Node3D.new()
	_handles_container.name = "HandlesContainer"
	_gizmo_root.add_child(_handles_container)

	# Build 3 Arrow Nodes (X, Y, Z)
	_arrow_instances.resize(3)
	for i in range(3):
		var arrow_node := Node3D.new()
		arrow_node.name = "Arrow_%d" % i

		# Shaft: Cylinder along +Y
		var shaft_mesh := CylinderMesh.new()
		shaft_mesh.top_radius = 0.025
		shaft_mesh.bottom_radius = 0.025
		shaft_mesh.height = 0.8
		var shaft_inst := MeshInstance3D.new()
		shaft_inst.name = "Shaft"
		shaft_inst.mesh = shaft_mesh
		shaft_inst.position = Vector3(0.0, 0.4, 0.0)
		shaft_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arrow_node.add_child(shaft_inst)

		# Tip: Cone along +Y
		var tip_mesh := CylinderMesh.new()
		tip_mesh.top_radius = 0.0
		tip_mesh.bottom_radius = 0.075
		tip_mesh.height = 0.22
		var tip_inst := MeshInstance3D.new()
		tip_inst.name = "Tip"
		tip_inst.mesh = tip_mesh
		tip_inst.position = Vector3(0.0, 0.91, 0.0)
		tip_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arrow_node.add_child(tip_inst)

		# Orient arrow according to axis
		if i == 0:
			# X: Rotate around Z by -90 deg -> points along +X
			arrow_node.rotation_degrees = Vector3(0.0, 0.0, -90.0)
			shaft_inst.material_override = _mat_x
			tip_inst.material_override = _mat_x
		elif i == 1:
			# Y: Points along +Y
			arrow_node.rotation_degrees = Vector3.ZERO
			shaft_inst.material_override = _mat_y
			tip_inst.material_override = _mat_y
		elif i == 2:
			# Z: Rotate around X by 90 deg -> points along +Z
			arrow_node.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			shaft_inst.material_override = _mat_z
			tip_inst.material_override = _mat_z

		_handles_container.add_child(arrow_node)
		_arrow_instances[i] = arrow_node

	# Build 3 Planar Quads (XY, XZ, YZ)
	_plane_instances.resize(3)
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(0.28, 0.28)

	for i in range(3):
		var plane_inst := MeshInstance3D.new()
		plane_inst.name = "Plane_%d" % i
		plane_inst.mesh = quad_mesh
		plane_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		if i == 0:
			# XY Plane (normal +Z, offset in +X and +Y)
			plane_inst.position = Vector3(0.25, 0.25, 0.0)
			plane_inst.rotation_degrees = Vector3.ZERO
			plane_inst.material_override = _mat_plane_xy
		elif i == 1:
			# XZ Plane (normal +Y, offset in +X and +Z)
			plane_inst.position = Vector3(0.25, 0.0, 0.25)
			plane_inst.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
			plane_inst.material_override = _mat_plane_xz
		elif i == 2:
			# YZ Plane (normal +X, offset in +Y and +Z)
			plane_inst.position = Vector3(0.0, 0.25, 0.25)
			plane_inst.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			plane_inst.material_override = _mat_plane_yz

		_handles_container.add_child(plane_inst)
		_plane_instances[i] = plane_inst

	# Build Guideline Instance (top-level world-space line)
	_guideline_instance = MeshInstance3D.new()
	_guideline_instance.name = "Guideline"
	_guideline_instance.top_level = true
	_guideline_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_guideline_instance.material_override = _mat_guideline
	_guideline_instance.visible = false
	_gizmo_root.add_child(_guideline_instance)

	# Build Wireframe Preview Instance (top-level world-space 12-line box)
	_wireframe_instance = MeshInstance3D.new()
	_wireframe_instance.name = "WireframePreview"
	_wireframe_instance.top_level = true
	_wireframe_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_wireframe_instance.material_override = _mat_wireframe
	_wireframe_instance.visible = false
	_gizmo_root.add_child(_wireframe_instance)


## Mounts the gizmo under the given scene root.
func mount(parent_node: Node) -> void:
	if _gizmo_root == null:
		return
	if parent_node != null and _gizmo_root.get_parent() != parent_node:
		if _gizmo_root.get_parent() != null:
			_gizmo_root.get_parent().remove_child(_gizmo_root)
		parent_node.add_child(_gizmo_root)


## Sets the blockout node and target element ID.
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

	_update_transform()
	if _gizmo_root != null:
		_gizmo_root.visible = true


func clear_target() -> void:
	_target_node = null
	_target_element_id = -1
	_hovered_handle = Handle.NONE
	_is_dragging = false
	_drag_handle = Handle.NONE
	hide_guideline()
	hide_wireframe_preview()
	if _gizmo_root != null:
		_gizmo_root.visible = false


func has_target() -> bool:
	return _target_node != null and _target_element_id != -1


func get_target_node() -> MapBlockoutNode3D:
	return _target_node


func get_target_element_id() -> int:
	return _target_element_id


func get_current_pos() -> Vector3:
	return _current_pos


func set_visible(p_visible: bool) -> void:
	if _gizmo_root != null:
		_gizmo_root.visible = p_visible and has_target()


func is_visible() -> bool:
	return _gizmo_root != null and _gizmo_root.visible


func set_handles_visible(p_visible: bool) -> void:
	if _handles_container != null:
		_handles_container.visible = p_visible


func set_position(p_pos: Vector3) -> void:
	_current_pos = p_pos
	_update_transform()


func set_rotation(p_rot: Vector3) -> void:
	_current_rot = p_rot
	_update_transform()


func refresh_from_target() -> void:
	if not has_target():
		return
	var idx: int = _target_node.blockout_data.find_element_index(_target_element_id)
	if idx == -1:
		clear_target()
		return
	_current_pos = _target_node.blockout_data.positions[idx]
	_current_rot = _target_node.blockout_data.rotations[idx]
	_current_size = _target_node.blockout_data.sizes[idx]
	_current_palette_id = _target_node.blockout_data.palette_ids[idx]
	_update_transform()


func _update_transform() -> void:
	if _gizmo_root == null:
		return
	_gizmo_root.position = _current_pos
	_gizmo_root.rotation_degrees = _current_rot


## Constant screen-space scaling: gizmo maintains ~75px footprint at any camera distance.
func update_camera_handles(camera: Camera3D) -> void:
	if not has_target() or camera == null or _handles_container == null or _gizmo_root == null:
		return

	var viewport_height: float = maxf(300.0, camera.get_viewport().get_visible_rect().size.y)
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		_cached_camera_scale = maxf(0.15, (75.0 / viewport_height) * camera.size)
	else:
		var cam_dist: float = camera.global_position.distance_to(_gizmo_root.global_position)
		var fov_rad: float = deg_to_rad(camera.fov)
		var world_height: float = 2.0 * cam_dist * tan(fov_rad * 0.5)
		_cached_camera_scale = maxf(0.15, (75.0 / viewport_height) * world_height)

	_handles_container.scale = Vector3.ONE * _cached_camera_scale


## Tests 2D screen distance to handles. Returns Handle enum or Handle.NONE.
func test_hit(camera: Camera3D, mouse_pos: Vector2, max_screen_dist: float = 16.0) -> int:
	if not has_target() or camera == null or not is_visible() or not _handles_container.visible:
		return Handle.NONE

	# Check Planar Quads first (Handle 3, 4, 5)
	for i in range(3):
		var plane_inst: MeshInstance3D = _plane_instances[i]
		var quad_center: Vector3 = plane_inst.global_position
		if camera.is_position_behind(quad_center):
			continue
		var quad_screen_pos: Vector2 = camera.unproject_position(quad_center)
		if mouse_pos.distance_to(quad_screen_pos) <= max_screen_dist * 1.4:
			return i + 3 # Handle.PLANE_XY, PLANE_XZ, PLANE_YZ

	# Check Axis Arrows (Handle 0, 1, 2)
	var best_handle: int = Handle.NONE
	var best_dist: float = max_screen_dist
	var best_cam_dist: float = INF

	for i in range(3):
		var arrow_node: Node3D = _arrow_instances[i]
		var shaft: MeshInstance3D = arrow_node.get_node("Shaft") as MeshInstance3D
		var tip: MeshInstance3D = arrow_node.get_node("Tip") as MeshInstance3D

		var shaft_tip: Vector3 = tip.global_position
		var shaft_base: Vector3 = arrow_node.global_position

		if camera.is_position_behind(shaft_tip):
			continue

		var p1: Vector2 = camera.unproject_position(shaft_base)
		var p2: Vector2 = camera.unproject_position(shaft_tip)

		var dist: float = _distance_point_to_segment_2d(mouse_pos, p1, p2)
		if dist <= best_dist:
			var cam_dist: float = camera.global_position.distance_to(shaft_tip)
			if cam_dist < best_cam_dist:
				best_dist = dist
				best_cam_dist = cam_dist
				best_handle = i

	return best_handle


func _distance_point_to_segment_2d(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 == 0.0:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	var proj := a + t * ab
	return p.distance_to(proj)


func set_hovered_handle(handle: int) -> void:
	if _hovered_handle == handle:
		return
	_hovered_handle = handle
	_update_handle_materials()


func _update_handle_materials() -> void:
	if _handles_container == null:
		return

	# Update arrows
	for i in range(3):
		var arrow_node: Node3D = _arrow_instances[i]
		var shaft: MeshInstance3D = arrow_node.get_node("Shaft") as MeshInstance3D
		var tip: MeshInstance3D = arrow_node.get_node("Tip") as MeshInstance3D
		var target_mat: StandardMaterial3D = null

		if _is_dragging and _drag_handle == i:
			target_mat = _mat_drag
		elif _hovered_handle == i:
			target_mat = _mat_hover
		else:
			if i == 0:
				target_mat = _mat_x
			elif i == 1:
				target_mat = _mat_y
			else:
				target_mat = _mat_z

		shaft.material_override = target_mat
		tip.material_override = target_mat

	# Update planes
	for i in range(3):
		var plane_inst: MeshInstance3D = _plane_instances[i]
		var handle_id: int = i + 3
		var target_mat: StandardMaterial3D = null

		if _is_dragging and _drag_handle == handle_id:
			target_mat = _mat_drag
		elif _hovered_handle == handle_id:
			target_mat = _mat_hover
		else:
			if i == 0:
				target_mat = _mat_plane_xy
			elif i == 1:
				target_mat = _mat_plane_xz
			else:
				target_mat = _mat_plane_yz

		plane_inst.material_override = target_mat


## Begins direct mouse-drag manipulation on the given handle.
func begin_drag(handle: int, camera: Camera3D, mouse_pos: Vector2) -> void:
	if not has_target() or handle == Handle.NONE or camera == null:
		return

	_is_dragging = true
	_drag_handle = handle
	_drag_start_pos = _current_pos
	_update_handle_materials()
	show_wireframe_preview(_current_pos, _current_size, _current_rot)

	var basis: Basis = _gizmo_root.global_transform.basis
	var origin: Vector3 = _gizmo_root.global_position

	match handle:
		Handle.PLANE_XY:
			_drag_plane = Plane(basis.z.normalized(), origin)
		Handle.PLANE_XZ:
			_drag_plane = Plane(basis.y.normalized(), origin)
		Handle.PLANE_YZ:
			_drag_plane = Plane(basis.x.normalized(), origin)
		Handle.AXIS_X:
			var axis_dir := basis.x.normalized()
			var cam_dir := (origin - camera.global_position).normalized()
			var plane_normal := cam_dir.cross(axis_dir).cross(axis_dir).normalized()
			_drag_plane = Plane(plane_normal if plane_normal.length_squared() > 0.01 else cam_dir, origin)
		Handle.AXIS_Y:
			var axis_dir := basis.y.normalized()
			var cam_dir := (origin - camera.global_position).normalized()
			var plane_normal := cam_dir.cross(axis_dir).cross(axis_dir).normalized()
			_drag_plane = Plane(plane_normal if plane_normal.length_squared() > 0.01 else cam_dir, origin)
		Handle.AXIS_Z:
			var axis_dir := basis.z.normalized()
			var cam_dir := (origin - camera.global_position).normalized()
			var plane_normal := cam_dir.cross(axis_dir).cross(axis_dir).normalized()
			_drag_plane = Plane(plane_normal if plane_normal.length_squared() > 0.01 else cam_dir, origin)

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_normal := camera.project_ray_normal(mouse_pos)
	var hit: Variant = _drag_plane.intersects_ray(ray_origin, ray_normal)
	if hit != null:
		_drag_hit_offset = (hit as Vector3) - origin
	else:
		_drag_hit_offset = Vector3.ZERO


## Updates position during direct mouse-drag manipulation. Returns new position.
func update_drag(camera: Camera3D, mouse_pos: Vector2, snap_enabled: bool, snap_size: float) -> Vector3:
	if not _is_dragging or camera == null or _drag_handle == Handle.NONE:
		return _current_pos

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_normal := camera.project_ray_normal(mouse_pos)
	var hit: Variant = _drag_plane.intersects_ray(ray_origin, ray_normal)
	if hit == null:
		return _current_pos

	var raw_world_pos: Vector3 = (hit as Vector3) - _drag_hit_offset
	var delta: Vector3 = raw_world_pos - _drag_start_pos
	var basis: Basis = _gizmo_root.global_transform.basis

	var constrained_delta: Vector3 = Vector3.ZERO
	match _drag_handle:
		Handle.AXIS_X:
			var axis: Vector3 = basis.x.normalized()
			constrained_delta = axis * delta.dot(axis)
		Handle.AXIS_Y:
			var axis: Vector3 = basis.y.normalized()
			constrained_delta = axis * delta.dot(axis)
		Handle.AXIS_Z:
			var axis: Vector3 = basis.z.normalized()
			constrained_delta = axis * delta.dot(axis)
		Handle.PLANE_XY:
			var normal: Vector3 = basis.z.normalized()
			constrained_delta = delta - normal * delta.dot(normal)
		Handle.PLANE_XZ:
			var normal: Vector3 = basis.y.normalized()
			constrained_delta = delta - normal * delta.dot(normal)
		Handle.PLANE_YZ:
			var normal: Vector3 = basis.x.normalized()
			constrained_delta = delta - normal * delta.dot(normal)

	if snap_enabled and snap_size > 0.001:
		match _drag_handle:
			Handle.AXIS_X:
				var axis: Vector3 = basis.x.normalized()
				var mag: float = snappedf(constrained_delta.dot(axis), snap_size)
				constrained_delta = axis * mag
			Handle.AXIS_Y:
				var axis: Vector3 = basis.y.normalized()
				var mag: float = snappedf(constrained_delta.dot(axis), snap_size)
				constrained_delta = axis * mag
			Handle.AXIS_Z:
				var axis: Vector3 = basis.z.normalized()
				var mag: float = snappedf(constrained_delta.dot(axis), snap_size)
				constrained_delta = axis * mag
			_:
				constrained_delta.x = snappedf(constrained_delta.x, snap_size)
				constrained_delta.y = snappedf(constrained_delta.y, snap_size)
				constrained_delta.z = snappedf(constrained_delta.z, snap_size)

	_current_pos = _drag_start_pos + constrained_delta
	_update_transform()
	show_wireframe_preview(_current_pos, _current_size, _current_rot)
	return _current_pos


func end_drag() -> Dictionary:
	if not _is_dragging:
		return {}

	var res := {
		"element_id": _target_element_id,
		"start_pos": _drag_start_pos,
		"final_pos": _current_pos,
		"rot": _current_rot,
		"size": _current_size,
		"palette_id": _current_palette_id
	}

	_is_dragging = false
	_drag_handle = Handle.NONE
	_update_handle_materials()
	hide_wireframe_preview()
	return res


func cancel_drag() -> void:
	if not _is_dragging:
		return
	_current_pos = _drag_start_pos
	_is_dragging = false
	_drag_handle = Handle.NONE
	_update_transform()
	_update_handle_materials()
	hide_wireframe_preview()


func is_dragging() -> bool:
	return _is_dragging


func get_drag_handle() -> int:
	return _drag_handle


## Renders a 3D wireframe box (12 lines) representing the preview of an element.
func show_wireframe_preview(center: Vector3, size: Vector3, rot_degrees: Vector3) -> void:
	if _wireframe_instance == null:
		return
	var imm := ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_LINES)
	var h := size * 0.5
	var corners: Array[Vector3] = [
		Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z),
		Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z),
		Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z),
		Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)
	]
	var edges: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 0),
		Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 4),
		Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7)
	]
	for edge in edges:
		imm.surface_add_vertex(corners[edge.x])
		imm.surface_add_vertex(corners[edge.y])
	imm.surface_end()

	_wireframe_instance.mesh = imm
	_wireframe_instance.global_position = center
	_wireframe_instance.global_rotation_degrees = rot_degrees
	_wireframe_instance.visible = true


func hide_wireframe_preview() -> void:
	if _wireframe_instance != null:
		_wireframe_instance.visible = false
		_wireframe_instance.mesh = null


func hide_preview() -> void:
	hide_wireframe_preview()


## Renders an infinite guideline along the active constraint vector.
func show_guideline(origin: Vector3, direction: Vector3, color: Color) -> void:
	if _guideline_instance == null:
		return
	var imm := ImmediateMesh.new()
	imm.surface_begin(Mesh.PRIMITIVE_LINES)
	imm.surface_set_color(color)
	var dir := direction.normalized()
	imm.surface_add_vertex(origin - dir * 1000.0)
	imm.surface_add_vertex(origin + dir * 1000.0)
	imm.surface_end()
	_guideline_instance.mesh = imm
	_guideline_instance.global_position = Vector3.ZERO
	_guideline_instance.global_rotation_degrees = Vector3.ZERO
	_guideline_instance.visible = true


func hide_guideline() -> void:
	if _guideline_instance != null:
		_guideline_instance.visible = false
		_guideline_instance.mesh = null


func teardown() -> void:
	clear_target()
	if _gizmo_root != null:
		if _gizmo_root.get_parent() != null:
			_gizmo_root.get_parent().remove_child(_gizmo_root)
		_gizmo_root.queue_free()
		_gizmo_root = null
