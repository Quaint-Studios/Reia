@tool
class_name ModifyBlockCommand
extends MapEditorCommand

## Reversible command that updates an element's transform, size, or palette in MapBlockoutData.

var blockout_node: MapBlockoutNode3D = null
var blockout_data: MapBlockoutData = null
var target_element_id: int = -1

var new_position: Vector3 = Vector3.ZERO
var new_rotation: Vector3 = Vector3.ZERO
var new_size: Vector3 = Vector3.ONE
var new_palette_id: int = -1

var old_position: Vector3 = Vector3.ZERO
var old_rotation: Vector3 = Vector3.ZERO
var old_size: Vector3 = Vector3.ONE
var old_palette_id: int = -1


func _init(
	p_node: MapBlockoutNode3D,
	p_element_id: int,
	p_new_pos: Vector3,
	p_new_rot: Vector3,
	p_new_size: Vector3,
	p_new_palette_id: int = -1
) -> void:
	super._init("Modify Block")
	blockout_node = p_node
	target_element_id = p_element_id
	if blockout_node != null:
		blockout_data = blockout_node.blockout_data
		_cache_old_state()

	new_position = p_new_pos
	new_rotation = p_new_rot
	new_size = p_new_size
	new_palette_id = p_new_palette_id


func _cache_old_state() -> void:
	if blockout_data == null:
		return
	var idx: int = blockout_data.find_element_index(target_element_id)
	if idx != -1:
		old_position = blockout_data.positions[idx]
		old_rotation = blockout_data.rotations[idx]
		old_size = blockout_data.sizes[idx]
		old_palette_id = blockout_data.palette_ids[idx]


func execute() -> bool:
	if blockout_data == null or target_element_id == -1:
		return false

	var old_chunk := MapBlockoutData.get_chunk_coord(old_position)
	var new_chunk := MapBlockoutData.get_chunk_coord(new_position)

	var success: bool = blockout_data.modify_element(
		target_element_id,
		new_position,
		new_rotation,
		new_size,
		new_palette_id
	)

	if success and blockout_node != null:
		blockout_node.rebuild_chunk(old_chunk)
		if old_chunk != new_chunk:
			blockout_node.rebuild_chunk(new_chunk)

	return success


func undo() -> bool:
	if blockout_data == null or target_element_id == -1:
		return false

	var current_chunk := MapBlockoutData.get_chunk_coord(new_position)
	var original_chunk := MapBlockoutData.get_chunk_coord(old_position)

	var success: bool = blockout_data.modify_element(
		target_element_id,
		old_position,
		old_rotation,
		old_size,
		old_palette_id
	)

	if success and blockout_node != null:
		blockout_node.rebuild_chunk(current_chunk)
		if current_chunk != original_chunk:
			blockout_node.rebuild_chunk(original_chunk)

	return success
