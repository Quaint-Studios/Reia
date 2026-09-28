@tool
class_name AddBlockCommand
extends MapEditorCommand

## Reversible command that adds a shape element to MapBlockoutData and rebuilds the local chunk.

var blockout_node: MapBlockoutNode3D = null
var blockout_data: MapBlockoutData = null

var shape_type: int = 0
var position: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO
var size: Vector3 = Vector3.ONE
var palette_id: int = 0

var created_element_id: int = -1
var target_chunk_coord: Vector2i = Vector2i.ZERO


func _init(
	p_node: MapBlockoutNode3D,
	p_shape_type: int,
	p_pos: Vector3,
	p_rot: Vector3,
	p_size: Vector3,
	p_palette_id: int = 0
) -> void:
	super._init("Add " + ShapeFlyoutContainer.get_shape_name(p_shape_type as ShapeFlyoutContainer.PrimitiveShape))
	blockout_node = p_node
	if blockout_node != null:
		blockout_data = blockout_node.blockout_data

	shape_type = p_shape_type
	position = p_pos
	rotation = p_rot
	size = p_size
	palette_id = p_palette_id
	target_chunk_coord = MapBlockoutData.get_chunk_coord(position)


func execute() -> bool:
	if blockout_node != null and blockout_data == null:
		blockout_data = blockout_node.blockout_data

	if blockout_data == null:
		printerr("[MapEditor] AddBlockCommand.execute() failed: blockout_data is null!")
		return false

	if blockout_node != null:
		blockout_node.is_command_updating = true

	created_element_id = blockout_data.add_element(
		shape_type,
		position,
		rotation,
		size,
		palette_id
	)

	if blockout_node != null:
		blockout_node.is_command_updating = false
		blockout_node.rebuild_chunk(target_chunk_coord)
	else:
		printerr("[MapEditor] AddBlockCommand.execute(): blockout_node is null!")

	return true


func undo() -> bool:
	if blockout_data == null or created_element_id == -1:
		return false

	if blockout_node != null:
		blockout_node.is_command_updating = true

	var success: bool = blockout_data.remove_element(created_element_id)

	if blockout_node != null:
		blockout_node.is_command_updating = false
		if success:
			blockout_node.rebuild_chunk(target_chunk_coord)

	return success
