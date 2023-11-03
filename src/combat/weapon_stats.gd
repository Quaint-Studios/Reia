class_name WeaponStats extends BaseStats

@export var weapon_type := WeaponType.Melee
enum WeaponType { Melee, Bow, Spell }

@export var damage_type: Enums.Element.Affinity
