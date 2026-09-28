@tool
class_name ShapeToolController
extends EditorToolController

## Tool controller for ToolMode.SHAPE.
## Manages two-phase interactive blockout extrusion (footprint drag + height extrusion),
## size previewing, and AddBlockCommand execution.

enum CreationPhase {
	HOVER,
	DRAGGING_BASE,
	EXTRUDING_HEIGHT
}

var _ghost_preview_manager: GhostPreviewManager = null

# Two-Phase Extrusion State
var _phase: CreationPhase = CreationPhase.HOVER
var _drag_start_pos: Vector3 = Vector3.ZERO
var _drag_current_pos: Vector3 = Vector3.ZERO
var _extrude_mouse_start_y: float = 0.0
var _is_click_mode: bool = false
var _drag_start_mouse_screen_pos: Vector2 = Vector2.ZERO

var _current_shape_center: Vector3 = Vector3.ZERO
var _current_shape_size: Vector3 = Vector3.ONE
var _current_shape_rot: Vector3 = Vector3.ZERO
var _last_snapped_pos: Vector3 = Vector3.ZERO
var _last_hit_valid: bool = false

var _active_primitive_shape: ShapeFlyoutContainer.PrimitiveShape = ShapeFlyoutContainer.PrimitiveShape.BOX


func setup(
	p_context: MapEditorContext,
	p_state_bus: MapEditorStateBus,
	p_command_history: MapEditorCommandHistory
) -> void:
	super.setup(p_context, p_state_bus, p_command_history)
	_ghost_preview_manager = GhostPreviewManager.new()

	if editor_state_bus != null:
		editor_state_bus.on_primitive_shape_changed.connect(_on_primitive_shape_changed)


func activate(scene_root: Node) -> void:
	super.activate(scene_root)
	_phase = CreationPhase.HOVER
	_is_click_mode = false
	if _ghost_preview_manager != null and scene_root != null:
		_ghost_preview_manager.mount(scene_root)


func deactivate() -> void:
	_cancel_creation()
	if _ghost_preview_manager != null:
		_ghost_preview_manager.hide()
	super.deactivate()


func cancel_operation() -> void:
	_cancel_creation()


func _cancel_creation() -> void:
	_phase = CreationPhase.HOVER
	_is_click_mode = false


func process_physics(
	_delta: float,
	camera: Camera3D,
	mouse_pos: Vector2,
	is_mouse_in_viewport: bool,
	scene_root: Node
) -> void:
	if not is_mouse_in_viewport or camera == null or scene_root == null:
		if _ghost_preview_manager != null:
			_ghost_preview_manager.hide()
		return

	if _ghost_preview_manager != null:
		_ghost_preview_manager.mount(scene_root)

	var snap_size: float = editor_context.grid_snap_size if editor_context.grid_snap_enabled else 0.0

	# Hover Phase
	if _phase == CreationPhase.HOVER:
		var hit := MapViewportRaycaster.cast_ray(
			camera,
			mouse_pos,
			editor_context.grid_snap_size,
			editor_context.grid_snap_enabled
		)
		if hit != null and hit.is_valid:
			_last_snapped_pos = hit.snapped_position
			_last_hit_valid = hit.is_valid

			var step: float = maxf(0.125, snap_size) if snap_size > 0.0 else 1.0
			if snap_size > 0.0:
				var cell_x: float = floorf(hit.hit_position.x / step) * step
				var cell_z: float = floorf(hit.hit_position.z / step) * step
				_current_shape_center = Vector3(cell_x + step * 0.5, hit.snapped_position.y, cell_z + step * 0.5)
				_current_shape_size = Vector3(step, step, step)
			else:
				_current_shape_center = hit.hit_position
				_current_shape_size = Vector3(1.0, 1.0, 1.0)
			_current_shape_rot = Vector3.ZERO

			if _ghost_preview_manager != null:
				_ghost_preview_manager.update_preview(_current_shape_center, hit.is_valid, _current_shape_size, _current_shape_rot)
		else:
			_last_hit_valid = false
			if _ghost_preview_manager != null:
				_ghost_preview_manager.hide()

	# Dragging Base Footprint Phase
	elif _phase == CreationPhase.DRAGGING_BASE:
		var hit := MapViewportRaycaster.cast_ray(
			camera,
			mouse_pos,
			editor_context.grid_snap_size,
			editor_context.grid_snap_enabled
		)
		if hit != null and hit.is_valid:
			_drag_current_pos = hit.hit_position
			_calculate_footprint(snap_size)
			if _ghost_preview_manager != null:
				_ghost_preview_manager.update_preview(_current_shape_center, true, _current_shape_size, _current_shape_rot)

	# Extruding Height Phase
	elif _phase == CreationPhase.EXTRUDING_HEIGHT:
		_calculate_height_extrusion(snap_size, mouse_pos.y)
		if _ghost_preview_manager != null:
			_ghost_preview_manager.update_preview(_current_shape_center, true, _current_shape_size, _current_shape_rot)


func _calculate_footprint(snap: float) -> void:
	var step: float = maxf(0.125, snap) if snap > 0.0 else 0.0

	var min_x: float = 0.0
	var max_x: float = 0.0
	var min_z: float = 0.0
	var max_z: float = 0.0

	if step > 0.0:
		var curr_cell_x: float = floorf(_drag_current_pos.x / step) * step
		var curr_cell_z: float = floorf(_drag_current_pos.z / step) * step
		min_x = minf(_drag_start_pos.x, curr_cell_x)
		max_x = maxf(_drag_start_pos.x, curr_cell_x) + step
		min_z = minf(_drag_start_pos.z, curr_cell_z)
		max_z = maxf(_drag_start_pos.z, curr_cell_z) + step
	else:
		min_x = minf(_drag_start_pos.x, _drag_current_pos.x)
		max_x = maxf(_drag_start_pos.x, _drag_current_pos.x)
		min_z = minf(_drag_start_pos.z, _drag_current_pos.z)
		max_z = maxf(_drag_start_pos.z, _drag_current_pos.z)
		if absf(max_x - min_x) < 0.1:
			max_x = min_x + 1.0
		if absf(max_z - min_z) < 0.1:
			max_z = min_z + 1.0

	var width: float = max_x - min_x
	var depth: float = max_z - min_z
	var center_x: float = (min_x + max_x) * 0.5
	var center_z: float = (min_z + max_z) * 0.5
	var initial_height: float = step if step > 0.0 else 1.0

	match _active_primitive_shape:
		ShapeFlyoutContainer.PrimitiveShape.BOX, ShapeFlyoutContainer.PrimitiveShape.PYRAMID, ShapeFlyoutContainer.PrimitiveShape.WEDGE:
			_current_shape_size = Vector3(width, initial_height, depth)
			_current_shape_rot = Vector3.ZERO
			_current_shape_center = Vector3(center_x, _drag_start_pos.y, center_z)

		ShapeFlyoutContainer.PrimitiveShape.CYLINDER, ShapeFlyoutContainer.PrimitiveShape.SPHERE, ShapeFlyoutContainer.PrimitiveShape.CAPSULE:
			var diameter: float = maxf(width, depth)
			_current_shape_size = Vector3(diameter, initial_height, diameter)
			_current_shape_rot = Vector3.ZERO
			_current_shape_center = Vector3(center_x, _drag_start_pos.y, center_z)


func _calculate_height_extrusion(snap: float, current_mouse_y: float) -> void:
	var delta_y: float = (_extrude_mouse_start_y - current_mouse_y) * 0.05
	var step: float = maxf(0.125, snap) if snap > 0.0 else 1.0
	var raw_height: float = maxf(step, absf(delta_y))
	var snapped_height: float = step * maxf(1.0, roundf(raw_height / step)) if snap > 0.0 else raw_height

	_current_shape_size.y = snapped_height


func forward_3d_gui_input(_camera: Camera3D, event: InputEvent) -> int:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return 0 # AFTER_GUI_INPUT_PASS

	# Mouse button interactions
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		# Cancel with right click
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			if _phase != CreationPhase.HOVER:
				_cancel_creation()
				return 1 # AFTER_GUI_INPUT_STOP

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			# Pass through camera navigation modifiers
			if mouse_event.alt_pressed or mouse_event.shift_pressed or mouse_event.ctrl_pressed:
				return 0

			# Left Click / Press
			if mouse_event.pressed:
				if _phase == CreationPhase.HOVER:
					if _last_hit_valid:
						var step: float = maxf(0.125, editor_context.grid_snap_size) if editor_context.grid_snap_enabled and editor_context.grid_snap_size > 0.0 else 0.0
						if step > 0.0:
							_drag_start_pos = Vector3(
								_current_shape_center.x - _current_shape_size.x * 0.5,
								_current_shape_center.y,
								_current_shape_center.z - _current_shape_size.z * 0.5
							)
						else:
							_drag_start_pos = _last_snapped_pos
						_drag_current_pos = _drag_start_pos
						_drag_start_mouse_screen_pos = mouse_event.position
						_phase = CreationPhase.DRAGGING_BASE
						_is_click_mode = false
						return 1

				elif _phase == CreationPhase.DRAGGING_BASE and _is_click_mode:
					_phase = CreationPhase.EXTRUDING_HEIGHT
					_extrude_mouse_start_y = mouse_event.position.y
					return 1

				elif _phase == CreationPhase.EXTRUDING_HEIGHT:
					_commit_shape(scene_root)
					return 1

			# Left Release
			elif not mouse_event.pressed:
				if _phase == CreationPhase.DRAGGING_BASE and not _is_click_mode:
					var screen_drag_dist: float = (mouse_event.position - _drag_start_mouse_screen_pos).length()
					if screen_drag_dist < 6.0:
						_is_click_mode = true
					else:
						_phase = CreationPhase.EXTRUDING_HEIGHT
						_extrude_mouse_start_y = mouse_event.position.y
					return 1

	return 0


func _commit_shape(scene_root: Node) -> void:
	_stamp_primitive_shape(
		scene_root,
		_current_shape_center,
		_active_primitive_shape as int,
		_current_shape_size,
		_current_shape_rot
	)
	_phase = CreationPhase.HOVER
	_is_click_mode = false


func _stamp_primitive_shape(
	scene_root: Node,
	ground_pos: Vector3,
	shape_type: int = 0,
	shape_size: Vector3 = Vector3.ONE,
	shape_rot: Vector3 = Vector3.ZERO
) -> void:
	if command_history == null or scene_root == null:
		return

	var blockout_node := MapBlockoutNode3D.find_or_create(scene_root)
	if blockout_node == null:
		return

	var final_pos: Vector3 = ground_pos + Vector3(0.0, shape_size.y * 0.5, 0.0)
	var cmd := AddBlockCommand.new(
		blockout_node,
		shape_type,
		final_pos,
		shape_rot,
		shape_size,
		0
	)
	command_history.execute_command(cmd)
	EditorInterface.mark_scene_as_unsaved()

	var shape_name: String = ShapeFlyoutContainer.get_shape_name(shape_type as ShapeFlyoutContainer.PrimitiveShape)
	print("[MapEditor] Committed %s at %v with size %v (Chunk: %v)" % [
		shape_name,
		final_pos,
		shape_size,
		MapBlockoutData.get_chunk_coord(final_pos)
	])

	if editor_state_bus != null:
		editor_state_bus.emit_request_viewport_redraw()


func _on_primitive_shape_changed(shape: int) -> void:
	_active_primitive_shape = shape as ShapeFlyoutContainer.PrimitiveShape
	if _ghost_preview_manager != null:
		_ghost_preview_manager.set_shape(_active_primitive_shape, Vector3.ONE)


func get_ghost_preview_manager() -> GhostPreviewManager:
	return _ghost_preview_manager


func teardown() -> void:
	if editor_state_bus != null and editor_state_bus.on_primitive_shape_changed.is_connected(_on_primitive_shape_changed):
		editor_state_bus.on_primitive_shape_changed.disconnect(_on_primitive_shape_changed)
	if _ghost_preview_manager != null:
		_ghost_preview_manager.teardown()
		_ghost_preview_manager = null
	super.teardown()
