class_name Item extends Resource

@export var id: int
@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: AtlasTexture
var item_type: ItemType
@export var item_grade: ItemGrade


enum ItemType { WEAPON, EQUIPMENT, MATERIAL, SOULSTONE }
enum ItemGrade { COMMON, UNCOMMON, RARE, SACRED, ARCANE, RADIANT }

func _toJSON_EXT():
	return {}

func toJSON() -> Dictionary:
	var data = {
		"id": id,
		"name": name,
		"description": description,
		"texture": texture.resource_path,
		"item_type": ItemType.keys()[item_type],
		"item_grade": ItemGrade.keys()[item_grade],
	}
	data.merge(_toJSON_EXT())

	return data
