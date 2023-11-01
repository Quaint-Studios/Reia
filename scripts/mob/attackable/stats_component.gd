class_name StatsComponent extends Resource

@export var health := 100:
	set(value):
		health = _set_health(value)
	get:
		return health
@export var max_health := 100:
	set(value):
		max_health = _set_health(value)
	get:
		return max_health
func _set_health(value: int) -> int:
	# health_manager.set_health(value, max_health)
	return value

@export var melee_power := 10
@export var bow_power := 10
@export var spell_power := 10

@export var melee_defense := 10
@export var bow_defense := 10
@export var spell_defense := 10

@export var crit_chance := 0.0
@export var crit_damage := 0.0

@export var weapon_damage := 5
@export var armor_defense := 3
@export var weapon_type := WeaponType.Melee

enum WeaponType { Melee, Bow, Spell }

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