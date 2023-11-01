class_name StatusComponent extends Resource

@export var curr_status: Status = Status.ALIVE
enum Status { ALIVE, DEAD, RESPAWNING }

func revive():
	pass
func die(attacker: Attackable): # , history: AttackHistory -> incoming/outgoing -> [ability | damage]
	pass
func respawn():
	pass
