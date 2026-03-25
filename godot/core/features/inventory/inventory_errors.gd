class_name InventoryErrors extends RefCounted

## Global registry for inventory-related error codes.
const NONE = 0
const TOO_FAR_FROM_BANK = 1
const INVENTORY_FULL = 2
const ITEM_LOCKED = 3

## Helper to pack/format errors for the network if necessary.
static func pack(error_code: int) -> int:
	return error_code
