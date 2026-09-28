@tool
class_name PrimitiveMeshFactory
extends RefCounted

## Domain factory for procedural 3D primitive meshes, collision shapes, and materials.

## Creates the default neutral prototype material (clean prototype grey, double-sided, subtle ambient fill).
static func create_default_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.68, 0.70, 0.77, 1.0)
	mat.roughness = 0.7
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Ambient emission fill ensures prototype blockouts are clearly visible in scenes without directional lights
	mat.emission_enabled = true
	mat.emission = Color(0.20, 0.22, 0.26)
	return mat


## Creates the semi-transparent holographic ghost material.
static func create_ghost_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.35, 0.65, 1.0, 0.45) # Soft translucent cyan-blue
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## Builds a Mesh resource for the requested primitive shape and dimensions.
static func build_mesh(shape: ShapeFlyoutContainer.PrimitiveShape, size: Vector3 = Vector3.ONE) -> Mesh:
	match shape:
		ShapeFlyoutContainer.PrimitiveShape.BOX:
			var box := BoxMesh.new()
			box.size = size
			return _primitive_to_array_mesh(box)

		ShapeFlyoutContainer.PrimitiveShape.SPHERE:
			var sphere := SphereMesh.new()
			sphere.radius = minf(size.x, size.z) * 0.5
			sphere.height = size.y
			return _primitive_to_array_mesh(sphere)

		ShapeFlyoutContainer.PrimitiveShape.CYLINDER:
			var cyl := CylinderMesh.new()
			cyl.top_radius = size.x * 0.5
			cyl.bottom_radius = size.x * 0.5
			cyl.height = size.y
			return _primitive_to_array_mesh(cyl)

		ShapeFlyoutContainer.PrimitiveShape.PYRAMID:
			return _build_pyramid_mesh(size)

		ShapeFlyoutContainer.PrimitiveShape.WEDGE:
			return _build_wedge_mesh(size)

		ShapeFlyoutContainer.PrimitiveShape.CAPSULE:
			var cap := CapsuleMesh.new()
			cap.radius = minf(size.x, size.z) * 0.5
			cap.height = size.y
			return _primitive_to_array_mesh(cap)

		_:
			var default_box := BoxMesh.new()
			default_box.size = size
			return _primitive_to_array_mesh(default_box)


## Builds a 6-face box ArrayMesh with outward-facing normals and proper triangulation.
static func _build_box_mesh(size: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5

	var p0 := Vector3(-hx, -hy, -hz)
	var p1 := Vector3(hx, -hy, -hz)
	var p2 := Vector3(hx, hy, -hz)
	var p3 := Vector3(-hx, hy, -hz)
	var p4 := Vector3(-hx, -hy, hz)
	var p5 := Vector3(hx, -hy, hz)
	var p6 := Vector3(hx, hy, hz)
	var p7 := Vector3(-hx, hy, hz)

	# Front face (+Z)
	st.set_normal(Vector3.BACK)
	st.add_vertex(p4); st.add_vertex(p5); st.add_vertex(p6)
	st.add_vertex(p4); st.add_vertex(p6); st.add_vertex(p7)

	# Back face (-Z)
	st.set_normal(Vector3.FORWARD)
	st.add_vertex(p1); st.add_vertex(p0); st.add_vertex(p3)
	st.add_vertex(p1); st.add_vertex(p3); st.add_vertex(p2)

	# Top face (+Y)
	st.set_normal(Vector3.UP)
	st.add_vertex(p3); st.add_vertex(p7); st.add_vertex(p6)
	st.add_vertex(p3); st.add_vertex(p6); st.add_vertex(p2)

	# Bottom face (-Y)
	st.set_normal(Vector3.DOWN)
	st.add_vertex(p0); st.add_vertex(p1); st.add_vertex(p5)
	st.add_vertex(p0); st.add_vertex(p5); st.add_vertex(p4)

	# Right face (+X)
	st.set_normal(Vector3.RIGHT)
	st.add_vertex(p5); st.add_vertex(p1); st.add_vertex(p2)
	st.add_vertex(p5); st.add_vertex(p2); st.add_vertex(p6)

	# Left face (-X)
	st.set_normal(Vector3.LEFT)
	st.add_vertex(p0); st.add_vertex(p4); st.add_vertex(p7)
	st.add_vertex(p0); st.add_vertex(p7); st.add_vertex(p3)

	return st.commit()


## Bakes a procedural PrimitiveMesh into a concrete ArrayMesh with explicit surface arrays.
static func _primitive_to_array_mesh(prim: PrimitiveMesh) -> ArrayMesh:
	var arr_mesh := ArrayMesh.new()
	var arrays: Array = prim.get_mesh_arrays()
	if not arrays.is_empty() and arrays[Mesh.ARRAY_VERTEX] != null and not (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return arr_mesh
	var st := SurfaceTool.new()
	st.create_from(prim, 0)
	var fallback: ArrayMesh = st.commit()
	if fallback != null and fallback.get_surface_count() > 0:
		return fallback
	return _build_box_mesh(Vector3.ONE)


## Builds a matching Shape3D collision resource for physics and navigation.
static func build_collision_shape(shape: ShapeFlyoutContainer.PrimitiveShape, size: Vector3 = Vector3.ONE) -> Shape3D:
	match shape:
		ShapeFlyoutContainer.PrimitiveShape.BOX:
			var box := BoxShape3D.new()
			box.size = size
			return box

		ShapeFlyoutContainer.PrimitiveShape.SPHERE:
			var sphere := SphereShape3D.new()
			sphere.radius = minf(size.x, size.z) * 0.5
			return sphere

		ShapeFlyoutContainer.PrimitiveShape.CYLINDER:
			var cyl := CylinderShape3D.new()
			cyl.radius = size.x * 0.5
			cyl.height = size.y
			return cyl

		ShapeFlyoutContainer.PrimitiveShape.PYRAMID:
			var convex := ConvexPolygonShape3D.new()
			var hx: float = size.x * 0.5
			var hy: float = size.y * 0.5
			var hz: float = size.z * 0.5
			convex.points = PackedVector3Array([
				Vector3(0.0, hy, 0.0),
				Vector3(-hx, -hy, hz),
				Vector3(hx, -hy, hz),
				Vector3(hx, -hy, -hz),
				Vector3(-hx, -hy, -hz),
			])
			return convex

		ShapeFlyoutContainer.PrimitiveShape.WEDGE:
			var convex := ConvexPolygonShape3D.new()
			var hx: float = size.x * 0.5
			var hy: float = size.y * 0.5
			var hz: float = size.z * 0.5
			convex.points = PackedVector3Array([
				Vector3(-hx, hy, -hz),
				Vector3(hx, hy, -hz),
				Vector3(-hx, -hy, -hz),
				Vector3(hx, -hy, -hz),
				Vector3(-hx, -hy, hz),
				Vector3(hx, -hy, hz),
			])
			return convex

		ShapeFlyoutContainer.PrimitiveShape.CAPSULE:
			var cap := CapsuleShape3D.new()
			cap.radius = minf(size.x, size.z) * 0.5
			cap.height = size.y
			return cap

		_:
			var default_shape := BoxShape3D.new()
			default_shape.size = size
			return default_shape


static func _build_pyramid_mesh(size: Vector3) -> ArrayMesh:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5

	var apex := Vector3(0.0, hy, 0.0)
	var b0 := Vector3(-hx, -hy, hz)  # front-left
	var b1 := Vector3(hx, -hy, hz)   # front-right
	var b2 := Vector3(hx, -hy, -hz)  # back-right
	var b3 := Vector3(-hx, -hy, -hz) # back-left

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var add_tri := func(v0: Vector3, v1: Vector3, v2: Vector3, norm: Vector3) -> void:
		var base: int = vertices.size()
		vertices.append(v0)
		vertices.append(v1)
		vertices.append(v2)
		normals.append(norm)
		normals.append(norm)
		normals.append(norm)
		uvs.append(Vector2(0.5, 0.0))
		uvs.append(Vector2(0.0, 1.0))
		uvs.append(Vector2(1.0, 1.0))
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)

	# Front face (+Z)
	var n_front: Vector3 = (b0 - apex).cross(b1 - apex).normalized()
	add_tri.call(apex, b0, b1, n_front)

	# Right face (+X)
	var n_right: Vector3 = (b1 - apex).cross(b2 - apex).normalized()
	add_tri.call(apex, b1, b2, n_right)

	# Back face (-Z)
	var n_back: Vector3 = (b2 - apex).cross(b3 - apex).normalized()
	add_tri.call(apex, b2, b3, n_back)

	# Left face (-X)
	var n_left: Vector3 = (b3 - apex).cross(b0 - apex).normalized()
	add_tri.call(apex, b3, b0, n_left)

	# Bottom face (-Y)
	add_tri.call(b0, b2, b1, Vector3.DOWN)
	add_tri.call(b0, b3, b2, Vector3.DOWN)

	var arr_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return arr_mesh


static func _build_wedge_mesh(size: Vector3) -> ArrayMesh:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5

	var top_left := Vector3(-hx, hy, -hz)
	var top_right := Vector3(hx, hy, -hz)
	var bot_back_left := Vector3(-hx, -hy, -hz)
	var bot_back_right := Vector3(hx, -hy, -hz)
	var bot_front_left := Vector3(-hx, -hy, hz)
	var bot_front_right := Vector3(hx, -hy, hz)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var add_tri := func(v0: Vector3, v1: Vector3, v2: Vector3, norm: Vector3, uv0: Vector2, uv1: Vector2, uv2: Vector2) -> void:
		var base: int = vertices.size()
		vertices.append(v0)
		vertices.append(v1)
		vertices.append(v2)
		normals.append(norm)
		normals.append(norm)
		normals.append(norm)
		uvs.append(uv0)
		uvs.append(uv1)
		uvs.append(uv2)
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)

	# Sloped ramp face (facing up-front)
	var n_ramp: Vector3 = (bot_front_left - top_left).cross(bot_front_right - top_left).normalized()
	add_tri.call(top_left, bot_front_left, bot_front_right, n_ramp, Vector2(0, 0), Vector2(0, 1), Vector2(1, 1))
	add_tri.call(top_left, bot_front_right, top_right, n_ramp, Vector2(0, 0), Vector2(1, 1), Vector2(1, 0))

	# Bottom face (ground, -Y)
	add_tri.call(bot_back_left, bot_back_right, bot_front_right, Vector3.DOWN, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
	add_tri.call(bot_back_left, bot_front_right, bot_front_left, Vector3.DOWN, Vector2(0, 0), Vector2(1, 1), Vector2(0, 1))

	# Back vertical face (-Z)
	add_tri.call(top_right, bot_back_right, bot_back_left, Vector3.FORWARD, Vector2(0, 0), Vector2(0, 1), Vector2(1, 1))
	add_tri.call(top_right, bot_back_left, top_left, Vector3.FORWARD, Vector2(0, 0), Vector2(1, 1), Vector2(1, 0))

	# Left triangular face (-X)
	add_tri.call(top_left, bot_back_left, bot_front_left, Vector3.LEFT, Vector2(0, 0), Vector2(0, 1), Vector2(1, 1))

	# Right triangular face (+X)
	add_tri.call(top_right, bot_front_right, bot_back_right, Vector3.RIGHT, Vector2(0, 0), Vector2(1, 1), Vector2(1, 0))

	var arr_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return arr_mesh
