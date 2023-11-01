class_name Attackable extends CharacterBody3D

@export var stats := StatsComponent.new()
@export var status := StatusComponent.new()

func init(_name = "Attackable"):
	name = _name # + _uuid

func _on_hit(attacker: Attackable):
	stats.damage(attacker)

	if stats.health == 0:
		status.die(attacker)
		return

func _attack(attackable: Attackable):
	attackable._on_hit(self)
