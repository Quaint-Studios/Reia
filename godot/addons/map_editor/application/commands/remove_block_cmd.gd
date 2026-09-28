@tool
class_name RemoveBlockCommand
extends MapEditorCommand

## Reversible command that removes an element from MapBlockoutData and rebuilds the local chunk.

var blockout_node: MapBlockoutNode3D = null
var blockout_data: MapBlockoutData = null

var target_element_id: int = -1
var target_chunk_coord: Vector2i = Vector2i.ZERO

# Preserved state for undo
var _saved_shape_type: int = 0
var _saved_position: Vector3 = Vector3.ZERO
var _saved_rotation: Vector3 = Vector3.ZERO
var _saved_size: Vector3 = Vector3.ONE
var _saved_palette_id: int = 0


func _init(p_node: MapBlockoutNode3D, p_element_id: int) -> void:
	super._init("Delete Block")
	blockout_node = p_node
	target_element_id = p_element_id
	if blockout_node != null:
		blockout_data = blockout_node.blockout_data
		_cache_element_state()


func _cache_element_state() -> void:
	if blockout_data == null:
		return
	var idx: int = blockout_data.find_element_index(target_element_id)
	if idx != -1:
		_saved_shape_type = blockout_data.shape_types[idx]
		_saved_position = blockout_data.positions[idx]
		_saved_rotation = blockout_data.rotations[idx]
		_saved_size = blockout_data.sizes[idx]
		_saved_palette_id = blockout_data.palette_ids[idx]
		target_chunk_coord = MapBlockoutData.get_chunk_coord(_saved_position)


func execute() -> bool:
	if blockout_data == null or target_element_id == -1:
		return false

	var success: bool = blockout_data.remove_element(target_element_id)
	if success and blockout_node != null:
		blockout_node.rebuild_chunk(target_chunk_coord)

	return success


func undo() -> bool:
	if blockout_data == null:
		return false

	target_element_id = blockout_data.add_element(
		_saved_shape_type,
		_saved_position,
		_saved_rotation,
		_saved_size,
		_saved_palette_id
	)

	if blockout_node != null:
		blockout_node.rebuild_chunk(target_chunk_coord)

	return true
