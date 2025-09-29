class_name FireballAbility
extends Ability

func _init() -> void:
	name = "Fireball"
	description = "Launches a fiery projectile that deals area damage."
	# icon = preload("res://assets/icons/fireball.png")
	
	cooldown = 0.25
	skill_power = 5.0
	multiplier = 1.5

	cost = 10
	cost_type = Enums.Resource_Type.ETHER
	mastery = 0.0

	element = Enums.Element_Affinity.PYRO

func get_power(power: int) -> int:
	return ceili(power + skill_power * multiplier)

func execute(_caster: Entity, target: Entity) -> void:
	if target == null:
		push_error("FireballAbility requires a target.")
		return
