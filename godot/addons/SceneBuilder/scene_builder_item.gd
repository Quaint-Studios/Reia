extends Resource
class_name SceneBuilderItem

@export var collection_name : String = "Temporary"
@export var item_name : String = "TempItemName"
@export var scene_path : String = ""

# Boolean
@export var use_random_vertical_offset : bool = false
@export var use_random_rotation : bool = false
@export var use_random_scale : bool = false

# Position
@export var random_offset_y_min : float = 0
@export var random_offset_y_max : float = 0

# Rotation
@export var random_rot_x : float = 0
@export var random_rot_z : float = 0
@export var random_rot_y : float = 0

# Scale
@export var random_scale_min : float = 0.9
@export var random_scale_max : float = 1.1

