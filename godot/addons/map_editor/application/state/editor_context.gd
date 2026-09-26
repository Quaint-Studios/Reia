class_name MapEditorContext
extends RefCounted

## Session state model for the Map Editor.
## Holds transient tool configurations, active snap settings, and current selection.

enum ToolMode {
	SELECT,
	TRANSLATE,
	ROTATE,
	SCALE,
	STAMP_PREFAB,
	PROCEDURAL_RAMP,
	PROCEDURAL_STAIR,
	WALL_PLACEMENT,
	APERTURE_INSERT,
	VERTEX_TINT,
}

var active_tool: ToolMode = ToolMode.SELECT
var grid_snap_enabled: bool = true
var grid_snap_size: float = 1.0
var angle_snap_enabled: bool = true
var angle_snap_degrees: float = 45.0
var surface_align_enabled: bool = true
var brush_radius: float = 5.0
var brush_falloff: float = 0.5
var brush_density: float = 1.0
var active_floor_slice: int = 1000
var selected_entities: Array[Node3D] = []


func get_angle_snap_radians() -> float:
	return deg_to_rad(angle_snap_degrees)


func clear_selection() -> void:
	selected_entities.clear()


func set_selection(entities: Array[Node3D]) -> void:
	selected_entities = entities.duplicate()


func add_to_selection(entity: Node3D) -> void:
	if not selected_entities.has(entity):
		selected_entities.append(entity)


func remove_from_selection(entity: Node3D) -> void:
	selected_entities.erase(entity)
