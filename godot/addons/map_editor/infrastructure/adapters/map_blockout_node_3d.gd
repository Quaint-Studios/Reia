@tool
class_name MapBlockoutNode3D
extends Node3D

## In-engine and runtime Node3D that mounts and renders MapBlockoutData.
## In the editor, displays live batched chunks and reacts to tool edits.
## At runtime, compiles and instantiates procedural meshes and trimesh collision in _ready().

@export var blockout_data: MapBlockoutData = null:
	set(val):
		if blockout_data != null and blockout_data.changed.is_connected(_on_data_changed):
			blockout_data.changed.disconnect(_on_data_changed)
		blockout_data = val
		if blockout_data != null:
			blockout_data.changed.connect(_on_data_changed)
		rebuild_all()

var _chunk_nodes: Dictionary = {} # Vector2i -> Node3D


func _ready() -> void:
	if blockout_data != null:
		if not blockout_data.changed.is_connected(_on_data_changed):
			blockout_data.changed.connect(_on_data_changed)
		rebuild_all()


## Rebuilds all spatial chunks from the assigned MapBlockoutData resource.
func rebuild_all() -> void:
	# Clear existing chunk nodes
	for coord: Vector2i in _chunk_nodes.keys():
		var node: Node = _chunk_nodes[coord]
		if is_instance_valid(node):
			node.queue_free()
	_chunk_nodes.clear()

	if blockout_data == null:
		return

	var all_chunks: Dictionary = ProceduralMeshBatcher.compile_all_chunks(blockout_data)
	for coord: Vector2i in all_chunks.keys():
		var chunk_result: ProceduralMeshBatcher.ChunkCompileResult = all_chunks[coord]
		_mount_chunk(chunk_result)


var is_command_updating: bool = false


## Rebuilds only a single 64m spatial chunk for sub-millisecond edit response.
func rebuild_chunk(coord: Vector2i) -> void:
	if blockout_data == null:
		printerr("[MapEditor] MapBlockoutNode3D: blockout_data is null in rebuild_chunk!")
		return

	var chunk_result: ProceduralMeshBatcher.ChunkCompileResult = ProceduralMeshBatcher.compile_chunk(blockout_data, coord)
	if chunk_result.is_empty:
		# If chunk is now empty, remove its visual/collision node
		if _chunk_nodes.has(coord):
			var node: Node = _chunk_nodes[coord]
			if is_instance_valid(node):
				remove_child(node)
				node.queue_free()
			_chunk_nodes.erase(coord)
	else:
		_mount_chunk(chunk_result)


func _mount_chunk(chunk_result: ProceduralMeshBatcher.ChunkCompileResult) -> void:
	var coord: Vector2i = chunk_result.chunk_coord
	var chunk_root: Node3D = null

	if _chunk_nodes.has(coord) and is_instance_valid(_chunk_nodes[coord]):
		chunk_root = _chunk_nodes[coord]
	else:
		chunk_root = Node3D.new()
		chunk_root.name = "Chunk_%d_%d" % [coord.x, coord.y]
		add_child(chunk_root)
		# Crucial: owner remains null so generated geometry is never serialized into .tscn
		chunk_root.owner = null
		_chunk_nodes[coord] = chunk_root

	# Batched Mesh Instance (reuse node for minimal RIDs)
	var mesh_inst: MeshInstance3D = chunk_root.get_node_or_null("BatchedMesh")
	if mesh_inst == null:
		mesh_inst = MeshInstance3D.new()
		mesh_inst.name = "BatchedMesh"
		mesh_inst.owner = null
		chunk_root.add_child(mesh_inst)

	mesh_inst.mesh = chunk_result.mesh
	mesh_inst.material_override = PrimitiveMeshFactory.create_default_material()
	mesh_inst.visible = true

	# StaticBody3D and Collision (Reuses node in place)
	var body: StaticBody3D = chunk_root.get_node_or_null("StaticBody3D")
	if body == null:
		body = StaticBody3D.new()
		body.name = "StaticBody3D"
		body.owner = null
		chunk_root.add_child(body)

	var col_shape: CollisionShape3D = body.get_node_or_null("CollisionShape3D")
	if col_shape == null:
		col_shape = CollisionShape3D.new()
		col_shape.name = "CollisionShape3D"
		col_shape.owner = null
		body.add_child(col_shape)

	col_shape.shape = chunk_result.collision_shape


func _on_data_changed() -> void:
	if is_command_updating:
		return
	if Engine.is_editor_hint():
		rebuild_all()


func get_active_chunk_count() -> int:
	return _chunk_nodes.size()


## Finds existing MapBlockoutNode3D in the scene or creates a default one.
static func find_or_create(scene_root: Node) -> MapBlockoutNode3D:
	if scene_root == null:
		return null

	if scene_root is MapBlockoutNode3D:
		var root_blockout := scene_root as MapBlockoutNode3D
		if root_blockout.blockout_data == null:
			root_blockout.blockout_data = MapBlockoutData.new()
		return root_blockout

	var existing: Node = scene_root.get_node_or_null("MapBlockout")
	if existing is MapBlockoutNode3D:
		var blockout := existing as MapBlockoutNode3D
		if blockout.blockout_data == null:
			blockout.blockout_data = MapBlockoutData.new()
		return blockout

	var new_blockout := MapBlockoutNode3D.new()
	new_blockout.name = "MapBlockout"
	new_blockout.blockout_data = MapBlockoutData.new()
	scene_root.add_child(new_blockout)
	new_blockout.owner = scene_root
	return new_blockout
