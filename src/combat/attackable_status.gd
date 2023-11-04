class_name AttackableStatus extends Resource

@export var curr_status: Status = Status.ALIVE
enum Status { ALIVE, DEAD, RESPAWNING }

func revive():
	pass
func die(attacker: Attackable):
	pass
func respawn():
	pass
