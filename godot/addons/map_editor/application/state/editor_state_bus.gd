class_name MapEditorStateBus
extends RefCounted

## Central signal bus for the Map Editor.
## Decouples presentation components, viewport handlers, and application services.

signal on_tool_changed(new_tool: int)
signal on_primitive_shape_changed(shape: int)
signal on_snap_settings_changed(grid_snap: bool, snap_size: float, angle_snap: bool, angle_degrees: float)
signal on_surface_align_toggled(enabled: bool)
signal on_selection_changed(selected_nodes: Array[Node3D])
signal on_blockout_element_selected(element_id: int)
signal on_floor_slice_changed(new_slice: int)
signal on_brush_settings_changed(radius: float, falloff: float, density: float)
signal on_palette_color_selected(color: Color)
signal on_diagnostics_updated(draw_calls: int, tris: int, lights: int)
signal on_request_viewport_redraw()


func emit_tool_changed(new_tool: int) -> void:
	on_tool_changed.emit(new_tool)


func emit_primitive_shape_changed(shape: int) -> void:
	on_primitive_shape_changed.emit(shape)


func emit_snap_settings_changed(grid_snap: bool, snap_size: float, angle_snap: bool, angle_degrees: float) -> void:
	on_snap_settings_changed.emit(grid_snap, snap_size, angle_snap, angle_degrees)


func emit_surface_align_toggled(enabled: bool) -> void:
	on_surface_align_toggled.emit(enabled)


func emit_selection_changed(selected_nodes: Array[Node3D]) -> void:
	on_selection_changed.emit(selected_nodes)


func emit_blockout_element_selected(element_id: int) -> void:
	on_blockout_element_selected.emit(element_id)


func emit_floor_slice_changed(new_slice: int) -> void:
	on_floor_slice_changed.emit(new_slice)


func emit_brush_settings_changed(radius: float, falloff: float, density: float) -> void:
	on_brush_settings_changed.emit(radius, falloff, density)


func emit_palette_color_selected(color: Color) -> void:
	on_palette_color_selected.emit(color)


func emit_diagnostics_updated(draw_calls: int, tris: int, lights: int) -> void:
	on_diagnostics_updated.emit(draw_calls, tris, lights)


func emit_request_viewport_redraw() -> void:
	on_request_viewport_redraw.emit()
