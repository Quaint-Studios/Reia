### @desc The base strength
class_name Attackable extends CharacterBody3D

var health = 100
var max_health = 100
var strength = 10
var defense = 2

var weapon_damage = 5
var armor_defense = 3

@export var health_manager: HealthManager

func _on_hit(attacker: Attackable, attackee: Attackable):
	if attackee.health == 0: return
	attackee.health -= (attacker.strength + attacker.weapon_damage) - (attackee.defense + attackee.armor_defense)
	attackee.health_manager.set_health(attackee.health, attackee.max_health)

func _attack(attackable: Attackable):
	attackable._on_hit(attackable, self)
