@tool
@abstract
class_name EditorToolController
extends RefCounted

## Abstract base class for in-viewport tool interactions.
## Defines lifecycle, input forwarding, physics tick processing, and cancellation hooks.

var editor_context: MapEditorContext = null
var editor_state_bus: MapEditorStateBus = null
var command_history: MapEditorCommandHistory = null
var is_active: bool = false


func setup(
	p_context: MapEditorContext,
	p_state_bus: MapEditorStateBus,
	p_command_history: MapEditorCommandHistory
) -> void:
	editor_context = p_context
	editor_state_bus = p_state_bus
	command_history = p_command_history


## Called when the user switches to this tool mode.
func activate(_scene_root: Node) -> void:
	is_active = true


## Called when the user switches away from this tool mode.
func deactivate() -> void:
	is_active = false


## Forwards 3D GUI events from EditorPlugin._forward_3d_gui_input.
## Returns EditorPlugin.AFTER_GUI_INPUT_PASS (0) or EditorPlugin.AFTER_GUI_INPUT_STOP (1).
@abstract func forward_3d_gui_input(_camera: Camera3D, _event: InputEvent) -> int


## Called every physics frame while this tool is active.
func process_physics(
	_delta: float,
	_camera: Camera3D,
	_mouse_pos: Vector2,
	_is_mouse_in_viewport: bool,
	_scene_root: Node
) -> void:
	pass


## Cancels any in-progress creation, drag, or interactive operation.
func cancel_operation() -> void:
	pass


## Cleans up all visual helpers and event bindings.
func teardown() -> void:
	deactivate()
	editor_context = null
	editor_state_bus = null
	command_history = null
