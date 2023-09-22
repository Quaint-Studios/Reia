### @desc The base strength
class_name Attackable extends CharacterBody3D

var health = 100
var max_health = 100
var strength = 10
var defense = 2

var weapon_damage = 5
var armor_defense = 3

@export var health_manager: HealthManager

func _on_hit(attacker: Attackable):
	if health == 0: return
	health -= (attacker.strength + attacker.weapon_damage) - (defense + armor_defense)
	health_manager.set_health(health, max_health)

func _attack(attackable: Attackable):
	attackable._on_hit(self)
