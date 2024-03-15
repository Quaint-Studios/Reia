class_name SpiritStats extends PlayerBaseStats

@export_category("Spirit Stats")
@export var weapon_stats := WeaponStats.new()

func get_power() -> int:
	match weapon_stats.weapon_type:
		Enums.Weapon_Type.MELEE:
			return melee_power + weapon_stats.melee_power
		Enums.Weapon_Type.BOW:
			return bow_power + weapon_stats.bow_power
		Enums.Weapon_Type.SPELL:
			return spell_power + weapon_stats.spell_power
		_:
			return 0

func get_defense(weapon_type: Enums.Weapon_Type) -> int:
	match weapon_type:
		Enums.Weapon_Type.MELEE:
			return melee_defense + weapon_stats.melee_defense
		Enums.Weapon_Type.BOW:
			return bow_defense + weapon_stats.bow_defense
		Enums.Weapon_Type.SPELL:
			return spell_defense + weapon_stats.spell_defense
		_:
			return 0
