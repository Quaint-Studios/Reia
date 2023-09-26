class_name Abilities

var player: Player

var cooldown = 0.0
var base_dmg = 1.0
var proficiency = 0.0 # out of 100%, how mastered it is -- how much it drains you

func _init(_player: Player):
	player = _player

func cast():
	pass
