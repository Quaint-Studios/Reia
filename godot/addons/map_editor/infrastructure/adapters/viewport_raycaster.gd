@tool
class_name MapViewportRaycaster
extends RefCounted

## Utility adapter for 3D viewport raycasting, physics surface intersection, and grid snapping.

class RaycastHitResult:
	var hit_position: Vector3 = Vector3.ZERO
	var snapped_position: Vector3 = Vector3.ZERO
	var surface_normal: Vector3 = Vector3.UP
	var collider: Object = null
	var is_valid: bool = false


## Casts a ray from the editor camera through screen_pos into the 3D world.
## Intersects physics collision bodies first, falling back to the Y=0 ground plane.
static func cast_ray(
	camera: Camera3D,
	screen_pos: Vector2,
	grid_snap_size: float = 1.0,
	snap_enabled: bool = true,
	exclude_rids: Array[RID] = []
) -> RaycastHitResult:
	var result := RaycastHitResult.new()
	if camera == null:
		return result

	var ray_origin: Vector3 = camera.project_ray_origin(screen_pos)
	var ray_normal: Vector3 = camera.project_ray_normal(screen_pos)

	# Raycast against physics collision bodies
	var world_3d := camera.get_world_3d()
	if world_3d != null:
		var space_state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
		if space_state == null and world_3d.space.is_valid():
			space_state = PhysicsServer3D.space_get_direct_state(world_3d.space)

		if space_state != null:
			var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_normal * 2000.0)
			if not exclude_rids.is_empty():
				query.exclude = exclude_rids

			var hit := space_state.intersect_ray(query)
			if not hit.is_empty():
				result.hit_position = hit["position"]
				result.surface_normal = hit["normal"]
				result.collider = hit.get("collider", null)
				result.is_valid = true

	# Fallback to Y = 0
	if not result.is_valid:
		var ground_plane := Plane(Vector3.UP, 0.0)
		var plane_hit: Variant = ground_plane.intersects_ray(ray_origin, ray_normal)
		if plane_hit != null:
			result.hit_position = plane_hit as Vector3
			result.surface_normal = Vector3.UP
			result.is_valid = true
		else:
			return result

	# Snap to grid
	if snap_enabled and grid_snap_size > 0.0:
		result.snapped_position = snap_to_grid(result.hit_position, grid_snap_size)
	else:
		result.snapped_position = result.hit_position

	return result


## Snaps a 3D coordinate to the nearest grid increment.
static func snap_to_grid(pos: Vector3, snap_size: float) -> Vector3:
	if snap_size <= 0.0:
		return pos
	return Vector3(
		snappedf(pos.x, snap_size),
		snappedf(pos.y, snap_size),
		snappedf(pos.z, snap_size)
	)
