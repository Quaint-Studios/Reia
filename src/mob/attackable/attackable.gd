class_name Attackable extends CharacterBody3D

@export var stats := AttackableStats.new()
@export var status := AttackableStatus.new()

func init(_name = "Attackable"):
	name = _name # + _uuid

func hit(attacker: Attackable):
	stats.damage(attacker)

	if stats.health == 0:
		status.die(attacker)
		return

func attack(attackable: Attackable): # , ability: Ability
	attackable.hit(self)
