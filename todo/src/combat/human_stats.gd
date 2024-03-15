class_name HumanStats extends PlayerBaseStats

@export_category("Human Stats")
@export var equipment_stats := EquipmentStats.new()
@export var combat_mode := Enums.Weapon_Type.MELEE # Humans can use all 3 types.

func get_power() -> int:
	match combat_mode:
		Enums.Weapon_Type.MELEE:
			return melee_power + equipment_stats.melee_power
		Enums.Weapon_Type.BOW:
			return bow_power + equipment_stats.bow_power
		Enums.Weapon_Type.SPELL:
			return spell_power + equipment_stats.spell_power
		_:
			return 0

func get_defense(weapon_type: Enums.Weapon_Type) -> int:
	match weapon_type:
		Enums.Weapon_Type.MELEE:
			return melee_defense + equipment_stats.melee_defense
		Enums.Weapon_Type.BOW:
			return bow_defense + equipment_stats.bow_defense
		Enums.Weapon_Type.SPELL:
			return spell_defense + equipment_stats.spell_defense
		_:
			return 0
