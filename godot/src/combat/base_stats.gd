class_name BaseStats extends Resource
## The base for all things that will ever have stats.

signal stats_changed(stats: BaseStats)

@export var melee_power := 10
@export var bow_power := 10
@export var spell_power := 10

@export var melee_defense := 10
@export var bow_defense := 10
@export var spell_defense := 10

@export var crit_chance := 0.0
@export var crit_damage := 0.0

func update() -> void:
	stats_changed.emit()
