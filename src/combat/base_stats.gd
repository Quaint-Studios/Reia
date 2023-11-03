class_name BaseStats extends Resource

signal stats_changed(stats: BaseStats)

@export var melee_power := 10
@export var bow_power := 10
@export var spell_power := 10

@export var melee_defense := 10
@export var bow_defense := 10
@export var spell_defense := 10

@export var crit_chance := 0.0
@export var crit_damage := 0.0

func _set(property: StringName, value: Variant) -> bool:
	stats_changed.emit(self)
	return super(property, value)
