class_name C_Weapon extends Item

@export var soulstones: Array[SoulstoneSlot]
# Experience increases everytime a weapon of the same type drops.
# It also increase slightly everytime the weapon is used.
# And it increases moderately everytime the weapon attacks.
var level := 1 # Caps out at 19, the 19th level is for upgrading the tier
var experience := 0.0 # TODO: Swap to int

func _init(_experience := 0.0, _level := 1) -> void:
	item_type = ItemType.WEAPON
	level = _level
	experience = _experience

static func calc_xp(grade: ItemGrade, level: int, xp: int) -> float:
	const multiplier := 100
	var new_xp := 0.0
	
	for i in ItemGrade.keys().size():
		new_xp = pow(log(pow(multiplier, i)), i) * (i * multiplier)
		# TODO: needs better calculations
	return new_xp

func level_up() -> void:
	xp_to_level(level, experience)

func xp_to_level(current_level: int, current_xp: float) -> void:
	const multiplier := 100
	# log(100^x)^x*(x*100)
	# TODO: simplify function
	var required_xp := pow(
		log(pow(multiplier, current_level)), current_level
	) * (current_level * multiplier)
	if current_xp >= required_xp:
		xp_to_level(current_level + 1, current_xp - required_xp)
	else:
		level_to_grade(current_level)

func level_to_grade(current_level: int) -> void:
	# TODO: Require ascension points on the item in the future to upgrade
	var new_grade := current_level / 20.0
	var new_level := int(fmod(new_grade, 1) * 20)
	new_grade = new_grade - (new_level / 20.0)
	
	item_grade = Item.ItemGrade.keys()[new_grade]
	level = new_level

# func _toJSON_EXT():
# 	return {
# 		"type": "weapon",
# 		"soulstones": soulstones,
# 		"level": level,
# 		"experience": experience
# 	}
