class_name Constants

const DEFAULT_ATLAS_SIZE = 128

# Items (May change)
const ITEM_GRADE_COMMON_COLOR = "d2d2d2ff"
const ITEM_GRADE_UNCOMMON_COLOR = "22d1ffff"
const ITEM_GRADE_RARE_COLOR = "7200f0ff"
const ITEM_GRADE_ARCANE_COLOR = "fdfd1cff"

# Inventory
const INVENTORY_ATLAS_SIZE: int = 128
const INVENTORY_BG_COLOR: String = "07263dc8"
const INVENTORY_FG_COLOR: String = "ffffffff"
const INVENTORY_MIN_BG_BLUR: float = 0.0
const INVENTORY_MAX_BG_BLUR: float = 3.0
static func INVENTORY_SELECTOR_POS(i: int) -> float: return -(81.25*((i-2)*2)-81.25) # Needs an offset to the left, partially works right now

# Game
const UI_DEFAULT_FPS = 30
const GAME_DEFAULT_FPS = 60
