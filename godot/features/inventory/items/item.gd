### This is a base item component for inventory items.
### It shouldn't be used directly. Instead, extend it for specific item types.
class_name Item extends Component

@export var id: int = 0
@export var name: String = "Item"
@export var description: String = "An item."
@export var icon: AtlasTexture
var item_type: ItemType
@export var item_grade: ItemGrade

enum ItemType {WEAPON, EQUIPMENT, MATERIAL, SOULSTONE}
enum ItemGrade {COMMON, UNCOMMON, RARE, SACRED, ARCANE, RADIANT}

# func _toJSON_EXT():
# 	return {}

# func toJSON() -> Dictionary:
# 	var data = {
# 		"id": id,
# 		"name": name,
# 		"description": description,
# 		"texture": texture.resource_path,
# 		"item_type": ItemType.keys()[item_type],
# 		"item_grade": ItemGrade.keys()[item_grade],
# 	}
# 	data.merge(_toJSON_EXT())

# 	return data
