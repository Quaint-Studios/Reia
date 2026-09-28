@tool
class_name SelectToolController
extends EditorToolController

## Tool controller for ToolMode.SELECT.
## Manages 3D oriented bounding box picking, 26-handle scaling, and element deletion.

var _gizmo: CornerHandleGizmo = null


func setup(
	p_context: MapEditorContext,
	p_state_bus: MapEditorStateBus,
	p_command_history: MapEditorCommandHistory
) -> void:
	super.setup(p_context, p_state_bus, p_command_history)
	_gizmo = CornerHandleGizmo.new()


func activate(scene_root: Node) -> void:
	super.activate(scene_root)
	if _gizmo != null and scene_root != null:
		_gizmo.mount(scene_root)


func deactivate() -> void:
	if _gizmo != null:
		if _gizmo.is_dragging():
			_gizmo.cancel_drag()
		_gizmo.clear_target()
	if editor_context != null:
		editor_context.clear_selection()
	if editor_state_bus != null:
		editor_state_bus.emit_blockout_element_selected(-1)
	super.deactivate()


func process_physics(
	_delta: float,
	camera: Camera3D,
	_mouse_pos: Vector2,
	_is_mouse_in_viewport: bool,
	scene_root: Node
) -> void:
	if _gizmo == null or scene_root == null:
		return

	_gizmo.mount(scene_root)
	if camera != null:
		_gizmo.update_camera_handles(camera)
	_gizmo.refresh_from_target()


func forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return 0 # AFTER_GUI_INPUT_PASS

	if _gizmo != null:
		_gizmo.mount(scene_root)

	# Key events (Delete, Backspace, Escape)
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			# Delete / Backspace: Delete selected element
			if key_event.keycode == KEY_DELETE or key_event.keycode == KEY_BACKSPACE:
				if _gizmo != null and _gizmo.has_target():
					var target_id: int = _gizmo.get_target_element_id()
					var blockout_node: MapBlockoutNode3D = _gizmo.get_target_node()
					if blockout_node != null and target_id != -1:
						var cmd := RemoveBlockCommand.new(blockout_node, target_id)
						command_history.execute_command(cmd)
						_gizmo.clear_target()
						if editor_context != null:
							editor_context.clear_selection()
						if editor_state_bus != null:
							editor_state_bus.emit_blockout_element_selected(-1)
						EditorInterface.mark_scene_as_unsaved()
						print("[MapEditor] Deleted element ID: %d" % target_id)
						return 1 # AFTER_GUI_INPUT_STOP

			# Escape: Cancel drag or clear selection
			if key_event.keycode == KEY_ESCAPE:
				if _gizmo != null and _gizmo.is_dragging():
					_gizmo.cancel_drag()
					return 1
				if _gizmo != null and _gizmo.has_target():
					_gizmo.clear_target()
					if editor_context != null:
						editor_context.clear_selection()
					if editor_state_bus != null:
						editor_state_bus.emit_blockout_element_selected(-1)
					return 1

	# Mouse motion
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		if _gizmo != null and _gizmo.has_target():
			if _gizmo.is_dragging():
				_gizmo.update_drag(
					camera,
					motion_event.position,
					editor_context.grid_snap_enabled,
					editor_context.grid_snap_size
				)
				return 1 # AFTER_GUI_INPUT_STOP
			else:
				_gizmo.update_camera_handles(camera)
				var hit_handle: int = _gizmo.test_handle_hit(camera, motion_event.position)
				_gizmo.set_hovered_handle(hit_handle)
		return 0 # AFTER_GUI_INPUT_PASS

	# Mouse button interactions
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		# Right Click: cancel drag
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if _gizmo != null and _gizmo.is_dragging():
				_gizmo.cancel_drag()
				return 1

		# Left Click
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Pass through camera navigation modifiers
			if mouse_event.alt_pressed or mouse_event.shift_pressed or mouse_event.ctrl_pressed:
				return 0

			# Pressed
			if mouse_event.pressed:
				# Test clicking handle on existing selection
				if _gizmo != null and _gizmo.has_target():
					var hit_handle: int = _gizmo.test_handle_hit(camera, mouse_event.position)
					if hit_handle != -1:
						_gizmo.begin_drag(hit_handle, camera, mouse_event.position)
						var handle_desc: String = _gizmo.get_handle_description(hit_handle)
						print("[MapEditor] Began scaling via %s on element %d" % [handle_desc, _gizmo.get_target_element_id()])
						return 1

				# Test raycast picking against blockout data elements
				var blockout_node := MapBlockoutNode3D.find_or_create(scene_root)
				if blockout_node != null and blockout_node.blockout_data != null:
					var ray_origin: Vector3 = camera.project_ray_origin(mouse_event.position)
					var ray_normal: Vector3 = camera.project_ray_normal(mouse_event.position)
					var local_ray_origin: Vector3 = blockout_node.global_transform.affine_inverse() * ray_origin
					var local_ray_normal: Vector3 = (blockout_node.global_transform.basis.inverse() * ray_normal).normalized()

					var picked_id: int = blockout_node.blockout_data.pick_element(local_ray_origin, local_ray_normal)
					if picked_id != -1:
						if editor_context != null:
							editor_context.select_element(picked_id)
						if _gizmo != null:
							_gizmo.set_target(blockout_node, picked_id)
						if editor_state_bus != null:
							editor_state_bus.emit_blockout_element_selected(picked_id)
						var shape_name: String = ShapeFlyoutContainer.get_shape_name(
							_gizmo.get_target_shape_type() as ShapeFlyoutContainer.PrimitiveShape
						) if _gizmo != null else "Element"
						print("[MapEditor] Selected %s (ID: %d)" % [shape_name, picked_id])
						return 1
					else:
						# Clicked empty space: clear selection
						if _gizmo != null and _gizmo.has_target():
							_gizmo.clear_target()
							if editor_context != null:
								editor_context.clear_selection()
							if editor_state_bus != null:
								editor_state_bus.emit_blockout_element_selected(-1)
							return 1

			# Released
			elif not mouse_event.pressed:
				if _gizmo != null and _gizmo.is_dragging():
					var handle_desc: String = _gizmo.get_handle_description(_gizmo.get_drag_handle_index())
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
							_gizmo.refresh_from_target()
							print("[MapEditor] Resized element %d via %s to size %v at %v" % [res.element_id, handle_desc, final_size, final_pos])
					return 1

	return 0


func cancel_operation() -> void:
	if _gizmo != null:
		if _gizmo.is_dragging():
			_gizmo.cancel_drag()
		elif _gizmo.has_target():
			_gizmo.clear_target()
			if editor_context != null:
				editor_context.clear_selection()
			if editor_state_bus != null:
				editor_state_bus.emit_blockout_element_selected(-1)


func get_gizmo() -> CornerHandleGizmo:
	return _gizmo


func teardown() -> void:
	if _gizmo != null:
		_gizmo.teardown()
		_gizmo = null
	super.teardown()
