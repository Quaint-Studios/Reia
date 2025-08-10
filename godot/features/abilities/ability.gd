class_name Ability extends Resource

@export var cooldown := 0.0
@export var base_dmg := 1.0
@export var proficiency := 0.0 # out of 100%, how mastered it is -- how much it drains you

@export var name: String = ""
@export var description: String = ""

@export var element: Enums.Element_Affinity

func get_damage(power: int) -> int:
	return ceili(power + base_dmg)
