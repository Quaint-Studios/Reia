@tool
class_name EditorInputRouter
extends RefCounted

## Central 3D viewport input router.
## Intercepts global hotkeys, tracks viewport mouse states, and delegates events
## to the active EditorToolController.

var editor_context: MapEditorContext = null
var editor_state_bus: MapEditorStateBus = null
var command_history: MapEditorCommandHistory = null

var _tools: Dictionary = {} # MapEditorContext.ToolMode -> EditorToolController
var _active_controller: EditorToolController = null

var _last_camera: Camera3D = null
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _is_mouse_in_viewport: bool = false


func setup(
	p_context: MapEditorContext,
	p_state_bus: MapEditorStateBus,
	p_command_history: MapEditorCommandHistory
) -> void:
	editor_context = p_context
	editor_state_bus = p_state_bus
	command_history = p_command_history

	# Register built-in tool controllers
	var select_tool := SelectToolController.new()
	select_tool.setup(editor_context, editor_state_bus, command_history)
	_tools[MapEditorContext.ToolMode.SELECT] = select_tool

	var shape_tool := ShapeToolController.new()
	shape_tool.setup(editor_context, editor_state_bus, command_history)
	_tools[MapEditorContext.ToolMode.SHAPE] = shape_tool

	if editor_state_bus != null:
		editor_state_bus.on_tool_changed.connect(_on_tool_changed)

	# Initial activation based on current context
	var initial_mode: MapEditorContext.ToolMode = editor_context.active_tool if editor_context != null else MapEditorContext.ToolMode.SELECT
	_switch_tool(initial_mode)


func _on_tool_changed(new_tool: int) -> void:
	_switch_tool(new_tool as MapEditorContext.ToolMode)


func _switch_tool(mode: MapEditorContext.ToolMode) -> void:
	if _active_controller != null:
		_active_controller.deactivate()

	if _tools.has(mode):
		_active_controller = _tools[mode]
		var scene_root: Node = EditorInterface.get_edited_scene_root()
		if _active_controller != null:
			_active_controller.activate(scene_root)
	else:
		_active_controller = null


## Handles global hotkeys and delegates unhandled events to the active tool.
func forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	_last_camera = viewport_camera

	# Global Viewport Hotkeys
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			# Q: Select Tool
			if key_event.keycode == KEY_Q and not key_event.alt_pressed and not key_event.ctrl_pressed and not key_event.meta_pressed:
				_cancel_active_operation()
				if editor_state_bus != null:
					editor_state_bus.emit_tool_changed(MapEditorContext.ToolMode.SELECT)
				return 1 # AFTER_GUI_INPUT_STOP

			# B: Shape Tool
			if key_event.keycode == KEY_B and not key_event.alt_pressed and not key_event.ctrl_pressed and not key_event.meta_pressed:
				_cancel_active_operation()
				if editor_state_bus != null:
					editor_state_bus.emit_tool_changed(MapEditorContext.ToolMode.SHAPE)
				return 1 # AFTER_GUI_INPUT_STOP

			# [: Halve grid snap size
			if key_event.keycode == KEY_BRACKETLEFT:
				_adjust_grid_snap(0.5)
				return 1

			# ]: Double grid snap size
			if key_event.keycode == KEY_BRACKETRIGHT:
				_adjust_grid_snap(2.0)
				return 1

			# Escape: cancel active operation
			if key_event.keycode == KEY_ESCAPE:
				if _active_controller != null:
					_active_controller.cancel_operation()
					return 1

	# Track mouse position and viewport presence
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		_last_mouse_pos = motion.position
		_is_mouse_in_viewport = true

	# Delegate to Active Controller
	if _active_controller != null:
		return _active_controller.forward_3d_gui_input(viewport_camera, event)

	return 0 # AFTER_GUI_INPUT_PASS


## Called from EditorPlugin._physics_process every frame.
func process_physics(delta: float) -> void:
	if _active_controller == null:
		return

	var scene_root: Node = EditorInterface.get_edited_scene_root()
	_active_controller.process_physics(
		delta,
		_last_camera,
		_last_mouse_pos,
		_is_mouse_in_viewport,
		scene_root
	)


func _adjust_grid_snap(multiplier: float) -> void:
	if editor_context == null:
		return

	var new_snap: float = clampf(editor_context.grid_snap_size * multiplier, 0.125, 16.0)
	editor_context.grid_snap_size = new_snap
	if editor_state_bus != null:
		editor_state_bus.emit_snap_settings_changed(
			editor_context.grid_snap_enabled,
			editor_context.grid_snap_size,
			editor_context.angle_snap_enabled,
			editor_context.angle_snap_degrees
		)


func _cancel_active_operation() -> void:
	if _active_controller != null:
		_active_controller.cancel_operation()


func get_tool_controller(mode: MapEditorContext.ToolMode) -> EditorToolController:
	if _tools.has(mode):
		return _tools[mode]
	return null


func get_active_controller() -> EditorToolController:
	return _active_controller


func teardown() -> void:
	if editor_state_bus != null and editor_state_bus.on_tool_changed.is_connected(_on_tool_changed):
		editor_state_bus.on_tool_changed.disconnect(_on_tool_changed)

	for tool_ctrl: EditorToolController in _tools.values():
		if tool_ctrl != null:
			tool_ctrl.teardown()
	_tools.clear()
	_active_controller = null

	editor_context = null
	editor_state_bus = null
	command_history = null
	_last_camera = null
