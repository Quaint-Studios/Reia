class_name Weapon extends LevelItem

@export var soulstones: Array[SoulstoneSlot]

func _init(_experience := 0, _level := 1) -> void:
	item_type = ItemType.WEAPON
	level = _level
	experience = _experience

func _toJSON_EXT() -> Dictionary:
	return {
		"type": "weapon",
		"soulstones": soulstones,
		"level": level,
		"experience": experience
	}
