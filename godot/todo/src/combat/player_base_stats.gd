class_name PlayerBaseStats extends AttackableStats

@export var ether := 100:
	set(value):
		if value < 0:
			ether = 0
		else:
			ether = value
	get:
		return ether
@export var max_ether := 100:
	set(value):
		if value < 1:
			max_ether = 1
		else:
			max_ether = value
	get:
		return max_ether
