### @desc The base strength
class_name Attackable extends CharacterBody3D

@export var health_manager: HealthManager

var health = 100
var max_health = 100
var strength = 10
var defense = 2

var weapon_damage = 5
var armor_defense = 3

var curr_status: STATUS = STATUS.ALIVE
enum STATUS { ALIVE, DEAD, RESPAWNING }

func init(_name = "Attackable"):
	name = _name # + _uuid

# turn these into signals so things can subscribe? to them?
func _on_died(_attacker: Attackable):
	print("")
	return

func _on_hit(attacker: Attackable):
	if health == 0:
		_on_died(attacker)
		return
	health -= (attacker.strength + attacker.weapon_damage) - (defense + armor_defense)
	health_manager.set_health(health, max_health)

func _attack(attackable: Attackable):
	attackable._on_hit(self)
