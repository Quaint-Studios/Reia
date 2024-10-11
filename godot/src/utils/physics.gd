class_name PhysicsUtils

const WALL_MASK: int = 1
const ATTACKABLE_MASK: int = 2
const PLAYER_MASK: int = 3
const NPC_MASK: int = 4
static var ENEMY_MASK: int = 5
const ITEM_MASK: int = 6

const GROUND_MASK: int = 9

# Converts an array of layer numbers to a collision mask.
static func arr_to_collision_mask(arr: PackedByteArray) -> int:
	var val := 0
	for num in arr:
		val += int(pow(2, num - 1))
	return val
