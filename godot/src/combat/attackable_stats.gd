class_name AttackableStats extends BaseStats
## The stats for an attackable. Generally just their raw stats.
## Use the extensions instead: PlayerStats & EnemeyStats

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
		if value < 0:
			health = 0
		else:
			health = value
		_emit_all()
	get:
		return health
@export var max_health := 100:
	set(value):
		if value < 1:
			max_health = 1
		else:
			max_health = value
		_emit_all()
	get:
		return max_health

# history: AttackHistory -> incoming/outgoing -> Array[<ability & damage struct>]

###
### Functionality
###
func damage(attacker: Attackable, ability: Ability = null):
	var attacker_power := attacker.stats.get_power()
	if ability != null:
		attacker_power = ability.get_damage(attacker_power)

	var defense := get_defense(attacker.stats.get_weapon_type())

	var attack_damage := attacker_power - defense
	if attack_damage < 0: attack_damage = 0

	health -= attack_damage

	if health < 0:
		health = 0

func get_weapon_type() -> Enums.Weapon_Type:
	#Override
	return Enums.Weapon_Type.MELEE

func get_power() -> int:
	# Override
	return 0

func get_defense(_weapon_type: Enums.Weapon_Type) -> int:
	# Override
	return 0
