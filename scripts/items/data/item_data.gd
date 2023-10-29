class_name ItemData extends Resource

@export var unique_id: int
@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: AtlasTexture
var item_type: ItemType

enum ItemType { WEAPON, EQUIPMENT, MATERIAL, SOULSTONE }
