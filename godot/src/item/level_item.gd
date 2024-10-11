class_name LevelItem extends Item

var level := 1 ## Caps out at 10, the 10th level is for upgrading the tier

## Experience increases everytime a weapon of the same type drops.
## It also increase slightly everytime the weapon is used.
## And it increases moderately everytime the weapon attacks.
var experience := 0

static func level_to_grade(lvl: int) -> ItemGrade:
	return ItemGrade.keys()[floori((lvl - 1) / 10.0)]

# Get the total experience required to reach a certain level.
static func get_level_xp(lvl: int) -> int:
	const PHI := (1 + sqrt(5)) / 2
	var multi := (161.8 + lvl) * sqrt(PHI) * (pow(2, lvl / 8.0) / PHI)
	var total_xp := floori(log(pow(multi, lvl)) * (lvl * multi))

	return total_xp

func add_xp(xp: int) -> void:
	experience += xp

	if experience >= get_level_xp(level):
		level_up()

func level_up() -> void:
	if level % 10 == 0:
		print("Requires an ascension item to continue leveling.")