@tool
class_name MapBlockoutData
extends Resource

## Lightweight, git-friendly resource storing procedural city blockout data.
## Utilizes flat packed buffers (Struct-of-Arrays) for maximum memory efficiency,
## sub-millisecond serialization, and is ready for a zero-copy GDExtension transition.

const CHUNK_SIZE: float = 64.0

@export var next_element_id: int = 1
@export var element_ids: PackedInt32Array = PackedInt32Array()
@export var shape_types: PackedInt32Array = PackedInt32Array()
@export var positions: PackedVector3Array = PackedVector3Array()
@export var rotations: PackedVector3Array = PackedVector3Array()
@export var sizes: PackedVector3Array = PackedVector3Array()
@export var palette_ids: PackedInt32Array = PackedInt32Array()


## Adds a new blockout element and returns its assigned unique ID.
func add_element(
	p_shape_type: int,
	p_pos: Vector3,
	p_rot: Vector3,
	p_size: Vector3,
	p_palette_id: int = 0
) -> int:
	var new_id: int = next_element_id
	next_element_id += 1

	element_ids.append(new_id)
	shape_types.append(p_shape_type)
	positions.append(p_pos)
	rotations.append(p_rot)
	sizes.append(p_size)
	palette_ids.append(p_palette_id)

	emit_changed()
	return new_id


## Removes an element by its unique ID. Returns true if found and removed.
func remove_element(p_id: int) -> bool:
	var idx: int = find_element_index(p_id)
	if idx == -1:
		return false

	element_ids.remove_at(idx)
	shape_types.remove_at(idx)
	positions.remove_at(idx)
	rotations.remove_at(idx)
	sizes.remove_at(idx)
	palette_ids.remove_at(idx)

	emit_changed()
	return true


## Modifies an existing element's transform, size, or palette ID.
func modify_element(
	p_id: int,
	p_pos: Vector3,
	p_rot: Vector3,
	p_size: Vector3,
	p_palette_id: int = -1
) -> bool:
	var idx: int = find_element_index(p_id)
	if idx == -1:
		return false

	positions[idx] = p_pos
	rotations[idx] = p_rot
	sizes[idx] = p_size
	if p_palette_id >= 0:
		palette_ids[idx] = p_palette_id

	emit_changed()
	return true


## Finds the array index for a given element ID. Returns -1 if not found.
func find_element_index(p_id: int) -> int:
	for i in range(element_ids.size()):
		if element_ids[i] == p_id:
			return i
	return -1


## Returns total number of active elements.
func get_element_count() -> int:
	return element_ids.size()


## Clears all elements from the blockout.
func clear_all() -> void:
	element_ids.clear()
	shape_types.clear()
	positions.clear()
	rotations.clear()
	sizes.clear()
	palette_ids.clear()
	next_element_id = 1
	emit_changed()


## Returns the 2D chunk coordinate (64m grid cell) for a given 3D position.
static func get_chunk_coord(p_pos: Vector3) -> Vector2i:
	return Vector2i(
		floori(p_pos.x / CHUNK_SIZE),
		floori(p_pos.z / CHUNK_SIZE)
	)


## Returns all unique chunk coordinates currently populated with elements.
func get_all_chunk_coords() -> Array[Vector2i]:
	var chunks: Array[Vector2i] = []
	for i in range(positions.size()):
		var coord := get_chunk_coord(positions[i])
		if not chunks.has(coord):
			chunks.append(coord)
	return chunks


## Returns all element array indices belonging to the specified spatial chunk.
func get_element_indices_in_chunk(p_chunk_coord: Vector2i) -> PackedInt32Array:
	var indices := PackedInt32Array()
	for i in range(positions.size()):
		if get_chunk_coord(positions[i]) == p_chunk_coord:
			indices.append(i)
	return indices


## Ray-casts against all elements' oriented bounding volumes.
## Returns the element ID of the closest hit, or -1 if no element was intersected.
func pick_element(ray_origin: Vector3, ray_normal: Vector3, max_distance: float = 2000.0) -> int:
	var closest_id: int = -1
	var closest_dist: float = max_distance

	for i in range(element_ids.size()):
		var pos: Vector3 = positions[i]
		var rot: Vector3 = rotations[i]
		var size: Vector3 = sizes[i]

		# Transform ray into element local space
		var basis := Basis.from_euler(rot)
		var inv_basis := basis.inverse()
		var local_origin: Vector3 = inv_basis * (ray_origin - pos)
		var local_normal: Vector3 = (inv_basis * ray_normal).normalized()

		# Test local ray against AABB centered at local origin
		var local_aabb := AABB(-size * 0.5, size)
		var hit_var: Variant = local_aabb.intersects_ray(local_origin, local_normal)
		if hit_var != null:
			var local_hit: Vector3 = hit_var as Vector3
			var world_hit: Vector3 = pos + (basis * local_hit)
			var dist: float = ray_origin.distance_to(world_hit)
			if dist < closest_dist:
				closest_dist = dist
				closest_id = element_ids[i]

	return closest_id
