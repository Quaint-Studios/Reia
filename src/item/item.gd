class_name Item extends Resource

@export var id: int
@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: AtlasTexture
var item_type: ItemType

enum ItemType { WEAPON, EQUIPMENT, MATERIAL, SOULSTONE }
