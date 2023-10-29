class_name WeaponData extends ItemData

@export var soulstones: Array[SoulstoneSlot]
# Experience increases everytime a weapon of the same type drops.
# It also increase slightly everytime the weapon is used.
# And it increases moderately everytime the weapon attacks.
var experience := 0.0

func _init(_experience := 0.0):
	item_type = ItemType.WEAPON
	experience = _experience
