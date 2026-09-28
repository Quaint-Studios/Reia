@tool
class_name ProceduralMeshBatcher
extends RefCounted

## Geometry compiler for MapBlockoutData.
## Compiles shapes into chunked ArrayMeshes and ConcavePolygonShape3D
## collisions to minimize draw calls.

class ChunkCompileResult:
	var chunk_coord: Vector2i = Vector2i.ZERO
	var mesh: ArrayMesh = null
	var collision_shape: Shape3D = null
	var element_count: int = 0
	var is_empty: bool = true


## Compiles all elements within a specific 64m spatial chunk into a unified mesh and collision shape.
static func compile_chunk(
	data: MapBlockoutData,
	chunk_coord: Vector2i,
	default_material: Material = null
) -> ChunkCompileResult:
	var result := ChunkCompileResult.new()
	result.chunk_coord = chunk_coord

	if data == null:
		return result

	var indices: PackedInt32Array = data.get_element_indices_in_chunk(chunk_coord)
	result.element_count = indices.size()
	if indices.is_empty():
		return result

	var active_material: Material = default_material
	if active_material == null:
		active_material = PrimitiveMeshFactory.create_default_material()

	# Group element indices by palette ID to minimize surface passes
	var palette_groups: Dictionary = {}
	for idx in indices:
		var pal_id: int = data.palette_ids[idx]
		if not palette_groups.has(pal_id):
			var arr: Array[int] = []
			palette_groups[pal_id] = arr
		(palette_groups[pal_id] as Array[int]).append(idx)

	print("[MapEditor] Batcher compile_chunk for coord %v: found %d elements, %d palette groups" % [
		chunk_coord,
		indices.size(),
		palette_groups.size()
	])

	var combined_mesh := ArrayMesh.new()

	for pal_id: int in palette_groups.keys():
		var group_indices: Array[int] = palette_groups[pal_id]
		var all_vertices := PackedVector3Array()
		var all_normals := PackedVector3Array()
		var all_uvs := PackedVector2Array()
		var all_indices := PackedInt32Array()

		print("[MapEditor] Batcher: Palette group %d has %d elements" % [pal_id, group_indices.size()])

		for idx in group_indices:
			var shape_type: ShapeFlyoutContainer.PrimitiveShape = data.shape_types[idx] as ShapeFlyoutContainer.PrimitiveShape
			var pos: Vector3 = data.positions[idx]
			var rot: Vector3 = data.rotations[idx]
			var size: Vector3 = data.sizes[idx]

			var element_mesh: Mesh = PrimitiveMeshFactory.build_mesh(shape_type, size)
			print("[MapEditor] Batcher: Element idx %d (%s) mesh: %s, surfaces: %d" % [
				idx,
				ShapeFlyoutContainer.get_shape_name(shape_type),
				element_mesh,
				element_mesh.get_surface_count() if element_mesh != null else -1
			])
			if element_mesh == null or element_mesh.get_surface_count() == 0:
				printerr("[MapEditor] Batcher: Failed to build mesh for element idx: ", idx)
				continue

			var surf_arrays: Array = element_mesh.surface_get_arrays(0)
			if surf_arrays.is_empty():
				printerr("[MapEditor] Batcher: Surface arrays empty for element idx: ", idx)
				continue

			var src_vertices: PackedVector3Array = surf_arrays[Mesh.ARRAY_VERTEX]
			if src_vertices.is_empty():
				continue

			var src_normals: PackedVector3Array = surf_arrays[Mesh.ARRAY_NORMAL]
			var src_uvs: PackedVector2Array = surf_arrays[Mesh.ARRAY_TEX_UV]
			var src_indices: PackedInt32Array = surf_arrays[Mesh.ARRAY_INDEX]

			var basis := Basis.from_euler(rot)
			var transform := Transform3D(basis, pos)
			var normal_basis: Basis = basis.inverse().transposed()

			var base_index: int = all_vertices.size()
			var vert_count: int = src_vertices.size()

			for v: Vector3 in src_vertices:
				all_vertices.append(transform * v)

			if src_normals.size() == vert_count:
				for n: Vector3 in src_normals:
					all_normals.append((normal_basis * n).normalized())
			else:
				for _i: int in range(vert_count):
					all_normals.append(Vector3.UP)

			if src_uvs.size() == vert_count:
				all_uvs.append_array(src_uvs)
			else:
				for _i: int in range(vert_count):
					all_uvs.append(Vector2.ZERO)

			if not src_indices.is_empty():
				for i: int in src_indices:
					all_indices.append(base_index + i)
			else:
				for i: int in range(vert_count):
					all_indices.append(base_index + i)

		if not all_vertices.is_empty():
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = all_vertices
			arrays[Mesh.ARRAY_NORMAL] = all_normals
			arrays[Mesh.ARRAY_TEX_UV] = all_uvs
			arrays[Mesh.ARRAY_INDEX] = all_indices

			combined_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var surf_idx: int = combined_mesh.get_surface_count() - 1
			if surf_idx >= 0:
				combined_mesh.surface_set_material(surf_idx, active_material)

	print("[MapEditor] Batcher: combined_mesh surfaces = %d" % combined_mesh.get_surface_count())

	if combined_mesh.get_surface_count() > 0:
		result.mesh = combined_mesh
		result.collision_shape = combined_mesh.create_trimesh_shape()
		result.is_empty = false

	return result


## Compiles all populated spatial chunks in the data into a Dictionary of results keyed by chunk coordinate.
static func compile_all_chunks(
	data: MapBlockoutData,
	default_material: Material = null
) -> Dictionary:
	var results: Dictionary = {}
	if data == null:
		return results

	var chunk_coords: Array[Vector2i] = data.get_all_chunk_coords()
	for coord in chunk_coords:
		var chunk_result := compile_chunk(data, coord, default_material)
		if not chunk_result.is_empty:
			results[coord] = chunk_result

	return results
