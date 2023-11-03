class_name AttackableStats extends BaseStats

###
### Signals
###
signal health_changed(value: int, max_health: int)
func _emit_all():
	health_changed.emit(health, max_health)
	stats_changed.emit(self)

###
### Variables
###
@export var health := 100:
	set(value):
		health = _set_health(value)
		_emit_all()
	get:
		return health
@export var max_health := 100:
	set(value):
		max_health = _set_health(value)
		_emit_all()
	get:
		return max_health
func _set_health(value: int) -> int:
	return value

@export var weapon_stats := WeaponStats.new()
@export var equipment_stats := EquipmentStats.new()

###
### Functionality
###
func damage(attacker: Attackable, ability: Ability = null):
	var attacker_power = attacker.stats.get_power()
	attacker_power += attacker.stats.weapon_damage
	if ability != null:
		attacker_power = ability.get_damage(attacker_power)

	var defense = get_defense(attacker.stats.weapon_type)
	defense += armor_defense

	health -= attacker_power - defense

func get_power() -> int:
	match weapon_type:
		WeaponType.Melee:
			return melee_power
		WeaponType.Bow:
			return bow_power
		WeaponType.Spell:
			return spell_power
		_:
			return 0

func get_defense(attack_type: WeaponType) -> int:
	match attack_type:
		WeaponType.Melee:
			return melee_defense
		WeaponType.Bow:
			return bow_defense
		WeaponType.Spell:
			return spell_defense
		_:
			return 0
