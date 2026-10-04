@tool
class_name SelectToolController
extends EditorToolController

## Tool controller for ToolMode.SELECT.
## Manages scaling the 26-handles and the 3-axis translation gizmos,
## along with Blender-style grab (G), scale (S), axis locking, and numeric typing.

enum InteractionMode {
	IDLE,
	SCALE_HANDLE_DRAG,
	TRANSLATE_GIZMO_DRAG,
	MODAL_GRAB,
	MODAL_SCALE
}

enum Constraint {
	NONE,
	GLOBAL_X,
	LOCAL_X,
	GLOBAL_Y,
	LOCAL_Y,
	GLOBAL_Z,
	LOCAL_Z,
	GLOBAL_PLANE_YZ,
	LOCAL_PLANE_YZ,
	GLOBAL_PLANE_XZ,
	LOCAL_PLANE_XZ,
	GLOBAL_PLANE_XY,
	LOCAL_PLANE_XY
}

var _gizmo: CornerHandleGizmo = null
var _trans_gizmo: TranslationGizmo = null

var _mode: InteractionMode = InteractionMode.IDLE
var _constraint: Constraint = Constraint.NONE
var _numeric_buffer: String = ""

# Cached state for modal operations
var _modal_start_pos: Vector3 = Vector3.ZERO
var _modal_start_rot: Vector3 = Vector3.ZERO
var _modal_start_size: Vector3 = Vector3.ONE
var _modal_start_palette: int = 0
var _modal_start_shape_type: int = 0
var _modal_mouse_screen_start: Vector2 = Vector2.ZERO
var _modal_ref_plane: Plane = Plane()
var _modal_ref_hit_start: Vector3 = Vector3.ZERO
var _modal_screen_center: Vector2 = Vector2.ZERO
var _modal_screen_start_dist: float = 1.0

# Live transform during modal operations
var _live_pos: Vector3 = Vector3.ZERO
var _live_size: Vector3 = Vector3.ONE
var _last_mouse_pos: Vector2 = Vector2.ZERO


func setup(
	p_context: MapEditorContext,
	p_state_bus: MapEditorStateBus,
	p_command_history: MapEditorCommandHistory
) -> void:
	super.setup(p_context, p_state_bus, p_command_history)
	_gizmo = CornerHandleGizmo.new()
	_trans_gizmo = TranslationGizmo.new()


func activate(scene_root: Node) -> void:
	super.activate(scene_root)
	if scene_root != null:
		if _gizmo != null:
			_gizmo.mount(scene_root)
		if _trans_gizmo != null:
			_trans_gizmo.mount(scene_root)


func deactivate() -> void:
	cancel_operation()
	if _gizmo != null:
		_gizmo.clear_target()
	if _trans_gizmo != null:
		_trans_gizmo.clear_target()
	if editor_context != null:
		editor_context.clear_selection()
	if editor_state_bus != null:
		editor_state_bus.emit_blockout_element_selected(-1)
	_clear_status()
	super.deactivate()


func process_physics(
	_delta: float,
	camera: Camera3D,
	_mouse_pos: Vector2,
	_is_mouse_in_viewport: bool,
	scene_root: Node
) -> void:
	if scene_root == null or camera == null:
		return

	if _gizmo != null:
		_gizmo.mount(scene_root)
	if _trans_gizmo != null:
		_trans_gizmo.mount(scene_root)

	if _mode == InteractionMode.IDLE:
		if _gizmo != null:
			_gizmo.update_camera_handles(camera)
			_gizmo.refresh_from_target()
		if _trans_gizmo != null:
			_trans_gizmo.update_camera_handles(camera)
			_trans_gizmo.refresh_from_target()


func forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null or camera == null:
		return 0 # AFTER_GUI_INPUT_PASS

	if _gizmo != null:
		_gizmo.mount(scene_root)
	if _trans_gizmo != null:
		_trans_gizmo.mount(scene_root)

	# Key events
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			# Modal active key handling
			if _mode == InteractionMode.MODAL_GRAB or _mode == InteractionMode.MODAL_SCALE:
				return _handle_modal_key(camera, key_event)

			# Idle key handling
			if _mode == InteractionMode.IDLE:
				# Delete / Backspace: Delete selected element
				if key_event.keycode == KEY_DELETE or key_event.keycode == KEY_BACKSPACE:
					return _handle_delete_key()

				# G: Start modal Grab
				if key_event.keycode == KEY_G and _has_target():
					_start_modal_grab(camera, _get_viewport_mouse(camera))
					return 1 # AFTER_GUI_INPUT_STOP

				# S: Start modal Scale
				if key_event.keycode == KEY_S and _has_target():
					_start_modal_scale(camera, _get_viewport_mouse(camera))
					return 1

				# Escape: Clear selection
				if key_event.keycode == KEY_ESCAPE:
					if _has_target():
						_clear_selection()
						return 1

	# Mouse motion
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		var mouse_pos := motion_event.position
		_last_mouse_pos = mouse_pos

		match _mode:
			InteractionMode.MODAL_GRAB:
				_update_modal_grab(camera, mouse_pos)
				return 1
			InteractionMode.MODAL_SCALE:
				_update_modal_scale(camera, mouse_pos)
				return 1
			InteractionMode.SCALE_HANDLE_DRAG:
				if _gizmo != null:
					_gizmo.update_drag(
						camera,
						mouse_pos,
						editor_context.grid_snap_enabled if editor_context != null else false,
						editor_context.grid_snap_size if editor_context != null else 1.0
					)
				return 1
			InteractionMode.TRANSLATE_GIZMO_DRAG:
				if _trans_gizmo != null:
					_trans_gizmo.update_drag(
						camera,
						mouse_pos,
						editor_context.grid_snap_enabled if editor_context != null else false,
						editor_context.grid_snap_size if editor_context != null else 1.0
					)
				return 1
			InteractionMode.IDLE:
				if _has_target():
					_update_hover(camera, mouse_pos)
				return 0

	# Mouse buttons
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var mouse_pos := mouse_event.position

		# Right Click: cancel active drag or modal
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if _mode == InteractionMode.MODAL_GRAB or _mode == InteractionMode.MODAL_SCALE:
				_cancel_modal()
				return 1
			if _mode == InteractionMode.SCALE_HANDLE_DRAG and _gizmo != null:
				_gizmo.cancel_drag()
				_mode = InteractionMode.IDLE
				_restore_gizmo_visibility()
				return 1
			if _mode == InteractionMode.TRANSLATE_GIZMO_DRAG and _trans_gizmo != null:
				_trans_gizmo.cancel_drag()
				_mode = InteractionMode.IDLE
				_restore_gizmo_visibility()
				return 1

		# Left Click
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Pass through camera navigation modifiers (Alt, Shift+MMB, etc.)
			if mouse_event.alt_pressed:
				return 0

			# Left Click Pressed
			if mouse_event.pressed:
				if _mode == InteractionMode.MODAL_GRAB or _mode == InteractionMode.MODAL_SCALE:
					_commit_modal()
					return 1

				if _mode == InteractionMode.IDLE:
					# Check Translation Gizmo handles first (Center origin)
					if _trans_gizmo != null and _trans_gizmo.has_target():
						var trans_hit: int = _trans_gizmo.test_hit(camera, mouse_pos)
						if trans_hit != TranslationGizmo.Handle.NONE:
							_mode = InteractionMode.TRANSLATE_GIZMO_DRAG
							if _gizmo != null:
								_gizmo.set_visible(false)
							_trans_gizmo.begin_drag(trans_hit, camera, mouse_pos)
							return 1

					# Check Scale Gizmo handles (Perimeter)
					if _gizmo != null and _gizmo.has_target():
						var scale_hit: int = _gizmo.test_handle_hit(camera, mouse_pos)
						if scale_hit != -1:
							_mode = InteractionMode.SCALE_HANDLE_DRAG
							if _trans_gizmo != null:
								_trans_gizmo.set_visible(false)
							_gizmo.begin_drag(scale_hit, camera, mouse_pos)
							return 1

					# Raycast picking against blockout data elements
					var blockout_node := MapBlockoutNode3D.find_or_create(scene_root)
					if blockout_node != null and blockout_node.blockout_data != null:
						var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
						var ray_normal: Vector3 = camera.project_ray_normal(mouse_pos)
						var local_origin: Vector3 = blockout_node.global_transform.affine_inverse() * ray_origin
						var local_normal: Vector3 = (blockout_node.global_transform.basis.inverse() * ray_normal).normalized()

						var picked_id: int = blockout_node.blockout_data.pick_element(local_origin, local_normal)
						if picked_id != -1:
							_set_selected_element(blockout_node, picked_id)
							return 1
						else:
							# Clicked empty space: clear selection
							if _has_target():
								_clear_selection()
								return 1

			# Left Click Released
			elif not mouse_event.pressed:
				if _mode == InteractionMode.SCALE_HANDLE_DRAG and _gizmo != null:
					_finish_scale_drag()
					return 1
				elif _mode == InteractionMode.TRANSLATE_GIZMO_DRAG and _trans_gizmo != null:
					_finish_translate_drag()
					return 1

	return 0


# --- Modal Key Event Handler ---

func _handle_modal_key(camera: Camera3D, key_event: InputEventKey) -> int:
	var shift := key_event.shift_pressed

	# Confirm on Enter
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		_commit_modal()
		return 1

	# Cancel on Escape
	if key_event.keycode == KEY_ESCAPE:
		_cancel_modal()
		return 1

	# Backspace in numeric buffer
	if key_event.keycode == KEY_BACKSPACE:
		if not _numeric_buffer.is_empty():
			_numeric_buffer = _numeric_buffer.substr(0, _numeric_buffer.length() - 1)
			_refresh_modal_with_mouse(camera)
		return 1

	# Digits / Dot / Minus for numeric buffer
	var unicode := key_event.unicode
	if (unicode >= 48 and unicode <= 57) or key_event.keycode == KEY_PERIOD or key_event.keycode == KEY_MINUS:
		var ch := String.chr(unicode) if unicode > 0 else ("." if key_event.keycode == KEY_PERIOD else "-")
		if ch == "-" and not _numeric_buffer.is_empty():
			pass # only allow minus at start
		elif ch == "." and _numeric_buffer.contains("."):
			pass # only allow one decimal point
		else:
			_numeric_buffer += ch
			_refresh_modal_with_mouse(camera)
		return 1

	# Axis constraint shortcuts
	match key_event.keycode:
		KEY_X:
			if shift:
				_cycle_plane_constraint(Constraint.GLOBAL_PLANE_YZ, Constraint.LOCAL_PLANE_YZ)
			else:
				_cycle_axis_constraint(Constraint.GLOBAL_X, Constraint.LOCAL_X)
			_refresh_modal_with_mouse(camera)
			return 1
		KEY_Y:
			if shift:
				_cycle_plane_constraint(Constraint.GLOBAL_PLANE_XZ, Constraint.LOCAL_PLANE_XZ)
			else:
				_cycle_axis_constraint(Constraint.GLOBAL_Y, Constraint.LOCAL_Y)
			_refresh_modal_with_mouse(camera)
			return 1
		KEY_Z:
			if shift:
				_cycle_plane_constraint(Constraint.GLOBAL_PLANE_XY, Constraint.LOCAL_PLANE_XY)
			else:
				_cycle_axis_constraint(Constraint.GLOBAL_Z, Constraint.LOCAL_Z)
			_refresh_modal_with_mouse(camera)
			return 1

	return 1


func _cycle_axis_constraint(global_c: Constraint, local_c: Constraint) -> void:
	if _constraint != global_c and _constraint != local_c:
		_constraint = global_c
	elif _constraint == global_c:
		_constraint = local_c
	else:
		_constraint = Constraint.NONE


func _cycle_plane_constraint(global_c: Constraint, local_c: Constraint) -> void:
	if _constraint != global_c and _constraint != local_c:
		_constraint = global_c
	elif _constraint == global_c:
		_constraint = local_c
	else:
		_constraint = Constraint.NONE


func _refresh_modal_with_mouse(camera: Camera3D) -> void:
	var mouse_pos := _get_viewport_mouse(camera)
	if _mode == InteractionMode.MODAL_GRAB:
		_update_modal_grab(camera, mouse_pos)
	elif _mode == InteractionMode.MODAL_SCALE:
		_update_modal_scale(camera, mouse_pos)


# --- Modal Grab Logic ---

func _start_modal_grab(camera: Camera3D, mouse_pos: Vector2) -> void:
	_mode = InteractionMode.MODAL_GRAB
	_constraint = Constraint.NONE
	_numeric_buffer = ""
	_cache_modal_start(camera, mouse_pos)

	if _gizmo != null:
		_gizmo.set_visible(false)
	if _trans_gizmo != null:
		_trans_gizmo.set_handles_visible(false)
		_trans_gizmo.show_wireframe_preview(_modal_start_pos, _modal_start_size, _modal_start_rot)

	_update_modal_grab(camera, mouse_pos)


func _update_modal_grab(camera: Camera3D, mouse_pos: Vector2) -> void:
	var basis := Basis.from_euler(_modal_start_rot)
	var delta := Vector3.ZERO
	var status_axis := "View Plane"
	var value_str := ""

	if not _numeric_buffer.is_empty():
		var num_val := _numeric_buffer.to_float()
		value_str = "%.2fm" % num_val
		match _constraint:
			Constraint.GLOBAL_X:
				delta = Vector3.RIGHT * num_val
				status_axis = "X (Global)"
			Constraint.LOCAL_X:
				delta = basis.x.normalized() * num_val
				status_axis = "X (Local)"
			Constraint.GLOBAL_Y:
				delta = Vector3.UP * num_val
				status_axis = "Y (Global)"
			Constraint.LOCAL_Y:
				delta = basis.y.normalized() * num_val
				status_axis = "Y (Local)"
			Constraint.GLOBAL_Z:
				delta = Vector3.BACK * num_val
				status_axis = "Z (Global)"
			Constraint.LOCAL_Z:
				delta = basis.z.normalized() * num_val
				status_axis = "Z (Local)"
			Constraint.GLOBAL_PLANE_YZ:
				delta = Vector3(0.0, num_val, num_val)
				status_axis = "YZ Plane (Global)"
			Constraint.LOCAL_PLANE_YZ:
				delta = (basis.y + basis.z).normalized() * num_val
				status_axis = "YZ Plane (Local)"
			Constraint.GLOBAL_PLANE_XZ:
				delta = Vector3(num_val, 0.0, num_val)
				status_axis = "XZ Plane (Global)"
			Constraint.LOCAL_PLANE_XZ:
				delta = (basis.x + basis.z).normalized() * num_val
				status_axis = "XZ Plane (Local)"
			Constraint.GLOBAL_PLANE_XY:
				delta = Vector3(num_val, num_val, 0.0)
				status_axis = "XY Plane (Global)"
			Constraint.LOCAL_PLANE_XY:
				delta = (basis.x + basis.y).normalized() * num_val
				status_axis = "XY Plane (Local)"
			_:
				delta = Vector3(num_val, 0.0, num_val)
				status_axis = "Free"
	else:
		var ray_origin := camera.project_ray_origin(mouse_pos)
		var ray_normal := camera.project_ray_normal(mouse_pos)
		var hit: Variant = _modal_ref_plane.intersects_ray(ray_origin, ray_normal)
		var raw_hit: Vector3 = (hit as Vector3) if hit != null else _modal_ref_hit_start
		var raw_delta: Vector3 = raw_hit - _modal_ref_hit_start

		match _constraint:
			Constraint.GLOBAL_X:
				delta = Vector3.RIGHT * raw_delta.x
				status_axis = "X (Global)"
			Constraint.LOCAL_X:
				var axis := basis.x.normalized()
				delta = axis * raw_delta.dot(axis)
				status_axis = "X (Local)"
			Constraint.GLOBAL_Y:
				delta = Vector3.UP * raw_delta.y
				status_axis = "Y (Global)"
			Constraint.LOCAL_Y:
				var axis := basis.y.normalized()
				delta = axis * raw_delta.dot(axis)
				status_axis = "Y (Local)"
			Constraint.GLOBAL_Z:
				delta = Vector3.BACK * raw_delta.z
				status_axis = "Z (Global)"
			Constraint.LOCAL_Z:
				var axis := basis.z.normalized()
				delta = axis * raw_delta.dot(axis)
				status_axis = "Z (Local)"
			Constraint.GLOBAL_PLANE_YZ:
				delta = Vector3(0.0, raw_delta.y, raw_delta.z)
				status_axis = "YZ Plane (Global)"
			Constraint.LOCAL_PLANE_YZ:
				var n := basis.x.normalized()
				delta = raw_delta - n * raw_delta.dot(n)
				status_axis = "YZ Plane (Local)"
			Constraint.GLOBAL_PLANE_XZ:
				delta = Vector3(raw_delta.x, 0.0, raw_delta.z)
				status_axis = "XZ Plane (Global)"
			Constraint.LOCAL_PLANE_XZ:
				var n := basis.y.normalized()
				delta = raw_delta - n * raw_delta.dot(n)
				status_axis = "XZ Plane (Local)"
			Constraint.GLOBAL_PLANE_XY:
				delta = Vector3(raw_delta.x, raw_delta.y, 0.0)
				status_axis = "XY Plane (Global)"
			Constraint.LOCAL_PLANE_XY:
				var n := basis.z.normalized()
				delta = raw_delta - n * raw_delta.dot(n)
				status_axis = "XY Plane (Local)"
			_:
				delta = raw_delta
				status_axis = "View Plane"

		# Grid snap
		if editor_context != null and editor_context.grid_snap_enabled and editor_context.grid_snap_size > 0.001:
			var snap: float = editor_context.grid_snap_size
			delta.x = snappedf(delta.x, snap)
			delta.y = snappedf(delta.y, snap)
			delta.z = snappedf(delta.z, snap)

		value_str = "%.2fm" % delta.length()

	_live_pos = _modal_start_pos + delta
	if _trans_gizmo != null:
		_trans_gizmo.set_position(_live_pos)
		_trans_gizmo.show_wireframe_preview(_live_pos, _modal_start_size, _modal_start_rot)
	_update_modal_guideline(basis)

	var status_text := "[Grab] Axis: %s | Offset: %s (LMB/Enter: Commit, RMB/Esc: Cancel)" % [status_axis, value_str]
	if not _numeric_buffer.is_empty():
		status_text = "[Grab] Axis: %s | Typed: %s (LMB/Enter: Commit, RMB/Esc: Cancel)" % [status_axis, _numeric_buffer]
	_emit_status(status_text)


# --- Modal Scale Logic ---

func _start_modal_scale(camera: Camera3D, mouse_pos: Vector2) -> void:
	_mode = InteractionMode.MODAL_SCALE
	_constraint = Constraint.NONE
	_numeric_buffer = ""
	_cache_modal_start(camera, mouse_pos)

	if _gizmo != null:
		_gizmo.set_visible(false)
	if _trans_gizmo != null:
		_trans_gizmo.set_handles_visible(false)
		_trans_gizmo.show_wireframe_preview(_modal_start_pos, _modal_start_size, _modal_start_rot)

	_update_modal_scale(camera, mouse_pos)


func _update_modal_scale(_camera: Camera3D, mouse_pos: Vector2) -> void:
	var basis := Basis.from_euler(_modal_start_rot)
	var factor: float = 1.0
	var status_axis := "Uniform"

	if not _numeric_buffer.is_empty():
		factor = maxf(0.01, _numeric_buffer.to_float())
	else:
		var current_dist: float = mouse_pos.distance_to(_modal_screen_center)
		factor = maxf(0.01, current_dist / _modal_screen_start_dist)

	var snap_enabled: bool = editor_context != null and editor_context.grid_snap_enabled and editor_context.grid_snap_size > 0.001
	var snap_step: float = editor_context.grid_snap_size if snap_enabled else 0.0

	var new_size := _modal_start_size
	match _constraint:
		Constraint.GLOBAL_X, Constraint.LOCAL_X:
			var target_x: float = _modal_start_size.x * factor
			if snap_enabled:
				target_x = maxf(snap_step, roundf(target_x / snap_step) * snap_step)
			new_size.x = maxf(0.1, target_x)
			status_axis = "X"
		Constraint.GLOBAL_Y, Constraint.LOCAL_Y:
			var target_y: float = _modal_start_size.y * factor
			if snap_enabled:
				target_y = maxf(snap_step, roundf(target_y / snap_step) * snap_step)
			new_size.y = maxf(0.1, target_y)
			status_axis = "Y"
		Constraint.GLOBAL_Z, Constraint.LOCAL_Z:
			var target_z: float = _modal_start_size.z * factor
			if snap_enabled:
				target_z = maxf(snap_step, roundf(target_z / snap_step) * snap_step)
			new_size.z = maxf(0.1, target_z)
			status_axis = "Z"
		_:
			for k in range(3):
				var target_k: float = _modal_start_size[k] * factor
				if snap_enabled:
					target_k = maxf(snap_step, roundf(target_k / snap_step) * snap_step)
				new_size[k] = maxf(0.1, target_k)
			status_axis = "Uniform"

	_live_size = new_size
	if _trans_gizmo != null:
		_trans_gizmo.show_wireframe_preview(_modal_start_pos, _live_size, _modal_start_rot)
	_update_modal_guideline(basis)

	var status_text := "[Scale] Axis: %s | Size: (%.2f, %.2f, %.2f) (LMB/Enter: Commit, RMB/Esc: Cancel)" % [status_axis, new_size.x, new_size.y, new_size.z]
	if not _numeric_buffer.is_empty():
		status_text = "[Scale] Axis: %s | Typed: %s (LMB/Enter: Commit, RMB/Esc: Cancel)" % [status_axis, _numeric_buffer]
	_emit_status(status_text)


# --- Modal Helpers ---

func _cache_modal_start(camera: Camera3D, mouse_pos: Vector2) -> void:
	var blockout_node := _gizmo.get_target_node() if _gizmo != null else null
	var target_id := _gizmo.get_target_element_id() if _gizmo != null else -1
	if blockout_node == null or target_id == -1 or blockout_node.blockout_data == null:
		return

	var idx := blockout_node.blockout_data.find_element_index(target_id)
	if idx == -1:
		return

	_modal_start_pos = blockout_node.blockout_data.positions[idx]
	_modal_start_rot = blockout_node.blockout_data.rotations[idx]
	_modal_start_size = blockout_node.blockout_data.sizes[idx]
	_modal_start_palette = blockout_node.blockout_data.palette_ids[idx]
	_modal_start_shape_type = blockout_node.blockout_data.shape_types[idx]
	_live_pos = _modal_start_pos
	_live_size = _modal_start_size
	_modal_mouse_screen_start = mouse_pos

	if camera != null:
		_modal_screen_center = camera.unproject_position(_modal_start_pos)
		_modal_screen_start_dist = maxf(12.0, mouse_pos.distance_to(_modal_screen_center))

		var cam_forward := -camera.global_transform.basis.z.normalized()
		_modal_ref_plane = Plane(cam_forward, _modal_start_pos)
		var hit: Variant = _modal_ref_plane.intersects_ray(
			camera.project_ray_origin(mouse_pos),
			camera.project_ray_normal(mouse_pos)
		)
		_modal_ref_hit_start = (hit as Vector3) if hit != null else _modal_start_pos


func _update_modal_guideline(basis: Basis) -> void:
	if _trans_gizmo == null:
		return
	match _constraint:
		Constraint.GLOBAL_X:
			_trans_gizmo.show_guideline(_modal_start_pos, Vector3.RIGHT, Color(0.88, 0.19, 0.19))
		Constraint.LOCAL_X:
			_trans_gizmo.show_guideline(_modal_start_pos, basis.x.normalized(), Color(0.88, 0.19, 0.19))
		Constraint.GLOBAL_Y:
			_trans_gizmo.show_guideline(_modal_start_pos, Vector3.UP, Color(0.18, 0.62, 0.27))
		Constraint.LOCAL_Y:
			_trans_gizmo.show_guideline(_modal_start_pos, basis.y.normalized(), Color(0.18, 0.62, 0.27))
		Constraint.GLOBAL_Z:
			_trans_gizmo.show_guideline(_modal_start_pos, Vector3.BACK, Color(0.10, 0.44, 0.76))
		Constraint.LOCAL_Z:
			_trans_gizmo.show_guideline(_modal_start_pos, basis.z.normalized(), Color(0.10, 0.44, 0.76))
		_:
			_trans_gizmo.hide_guideline()


func _commit_modal() -> void:
	if _trans_gizmo != null:
		_trans_gizmo.hide_guideline()
		_trans_gizmo.hide_wireframe_preview()
	_clear_status()

	var blockout_node := _gizmo.get_target_node() if _gizmo != null else null
	var target_id := _gizmo.get_target_element_id() if _gizmo != null else -1
	if blockout_node != null and target_id != -1:
		if _live_pos != _modal_start_pos or _live_size != _modal_start_size:
			var cmd := ModifyBlockCommand.new(
				blockout_node,
				target_id,
				_live_pos,
				_modal_start_rot,
				_live_size,
				_modal_start_palette
			)
			command_history.execute_command(cmd)
			EditorInterface.mark_scene_as_unsaved()

	_mode = InteractionMode.IDLE
	_numeric_buffer = ""
	_restore_gizmo_visibility()


func _cancel_modal() -> void:
	if _trans_gizmo != null:
		_trans_gizmo.hide_guideline()
		_trans_gizmo.hide_wireframe_preview()
	_clear_status()

	_mode = InteractionMode.IDLE
	_numeric_buffer = ""
	_restore_gizmo_visibility()


func _restore_gizmo_visibility() -> void:
	if _gizmo != null:
		_gizmo.set_visible(true)
		_gizmo.refresh_from_target()
	if _trans_gizmo != null:
		_trans_gizmo.set_handles_visible(true)
		_trans_gizmo.set_visible(true)
		_trans_gizmo.refresh_from_target()


# --- Direct Drag Completion ---

func _finish_scale_drag() -> void:
	if _gizmo == null:
		_mode = InteractionMode.IDLE
		return
	var res: Dictionary = _gizmo.end_drag()
	if not res.is_empty():
		var start_size: Vector3 = res.start_size
		var final_size: Vector3 = res.final_size
		var start_pos: Vector3 = res.start_pos
		var final_pos: Vector3 = res.final_pos
		if start_size != final_size or start_pos != final_pos:
			var cmd := ModifyBlockCommand.new(
				_gizmo.get_target_node(),
				res.element_id,
				final_pos,
				res.final_rot,
				final_size,
				res.palette_id
			)
			command_history.execute_command(cmd)
			EditorInterface.mark_scene_as_unsaved()
	_mode = InteractionMode.IDLE
	_restore_gizmo_visibility()


func _finish_translate_drag() -> void:
	if _trans_gizmo == null:
		_mode = InteractionMode.IDLE
		return
	var res: Dictionary = _trans_gizmo.end_drag()
	if not res.is_empty():
		var start_pos: Vector3 = res.start_pos
		var final_pos: Vector3 = res.final_pos
		if start_pos != final_pos:
			var cmd := ModifyBlockCommand.new(
				_trans_gizmo.get_target_node(),
				res.element_id,
				final_pos,
				res.rot,
				res.size,
				res.palette_id
			)
			command_history.execute_command(cmd)
			EditorInterface.mark_scene_as_unsaved()
	_mode = InteractionMode.IDLE
	_restore_gizmo_visibility()


# --- Hover & Selection Helpers ---

func _update_hover(camera: Camera3D, mouse_pos: Vector2) -> void:
	if _trans_gizmo == null or _gizmo == null:
		return

	_trans_gizmo.update_camera_handles(camera)
	_gizmo.update_camera_handles(camera)

	var trans_hit: int = _trans_gizmo.test_hit(camera, mouse_pos)
	if trans_hit != TranslationGizmo.Handle.NONE:
		_trans_gizmo.set_hovered_handle(trans_hit)
		_gizmo.set_hovered_handle(-1)
	else:
		_trans_gizmo.set_hovered_handle(TranslationGizmo.Handle.NONE)
		var scale_hit: int = _gizmo.test_handle_hit(camera, mouse_pos)
		_gizmo.set_hovered_handle(scale_hit)


func _set_selected_element(blockout_node: MapBlockoutNode3D, picked_id: int) -> void:
	if editor_context != null:
		editor_context.select_element(picked_id)
	if _gizmo != null:
		_gizmo.set_target(blockout_node, picked_id)
	if _trans_gizmo != null:
		_trans_gizmo.set_target(blockout_node, picked_id)
	if editor_state_bus != null:
		editor_state_bus.emit_blockout_element_selected(picked_id)


func _clear_selection() -> void:
	if _gizmo != null:
		_gizmo.clear_target()
	if _trans_gizmo != null:
		_trans_gizmo.clear_target()
	if editor_context != null:
		editor_context.clear_selection()
	if editor_state_bus != null:
		editor_state_bus.emit_blockout_element_selected(-1)
	_clear_status()


func _handle_delete_key() -> int:
	if not _has_target():
		return 0
	var target_id: int = _gizmo.get_target_element_id()
	var blockout_node: MapBlockoutNode3D = _gizmo.get_target_node()
	if blockout_node != null and target_id != -1:
		var cmd := RemoveBlockCommand.new(blockout_node, target_id)
		command_history.execute_command(cmd)
		_clear_selection()
		EditorInterface.mark_scene_as_unsaved()
		return 1
	return 0


func _has_target() -> bool:
	return _gizmo != null and _gizmo.has_target()


func _get_viewport_mouse(_camera: Camera3D) -> Vector2:
	if _last_mouse_pos != Vector2.ZERO:
		return _last_mouse_pos
	return EditorInterface.get_editor_viewport_3d(0).get_mouse_position()


func _emit_status(status_text: String) -> void:
	if editor_state_bus != null:
		editor_state_bus.emit_transform_status_changed(status_text)


func _clear_status() -> void:
	_emit_status("")


func cancel_operation() -> void:
	if _mode == InteractionMode.MODAL_GRAB or _mode == InteractionMode.MODAL_SCALE:
		_cancel_modal()
	elif _mode == InteractionMode.SCALE_HANDLE_DRAG and _gizmo != null:
		_gizmo.cancel_drag()
		_mode = InteractionMode.IDLE
		_restore_gizmo_visibility()
	elif _mode == InteractionMode.TRANSLATE_GIZMO_DRAG and _trans_gizmo != null:
		_trans_gizmo.cancel_drag()
		_mode = InteractionMode.IDLE
		_restore_gizmo_visibility()
	elif _has_target():
		_clear_selection()


func get_gizmo() -> CornerHandleGizmo:
	return _gizmo


func get_translation_gizmo() -> TranslationGizmo:
	return _trans_gizmo


func teardown() -> void:
	if _gizmo != null:
		_gizmo.teardown()
		_gizmo = null
	if _trans_gizmo != null:
		_trans_gizmo.teardown()
		_trans_gizmo = null
	super.teardown()
