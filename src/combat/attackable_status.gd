class_name AttackableStatus extends Resource

signal state_changed(state: Status)

@export var state := Status.ALIVE:
	set(value):
		state = value
		state_changed.emit(value)
enum Status { ALIVE, DEAD, RESPAWNING }

func revive():
	state = Status.ALIVE

func die(attacker: Attackable):
	state = Status.DEAD

func respawn():
	state = Status.RESPAWNING
