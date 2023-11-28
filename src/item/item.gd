class_name Item extends Resource

@export var id: int
@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: AtlasTexture
var item_type: ItemType
@export var item_grade: ItemGrade

enum ItemType { WEAPON, EQUIPMENT, MATERIAL, SOULSTONE }
enum ItemGrade { COMMON, UNCOMMON, RARE, SACRED, ARCANE, RADIANT }
