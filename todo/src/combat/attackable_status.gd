class_name AttackableStatus extends Resource

signal is_alive
signal is_dead
signal is_respawning

@export var state := Status.ALIVE:
	set(value):
		state = value
		match value:
			Status.ALIVE:
				is_alive.emit()
			Status.DEAD:
				is_dead.emit()
			Status.RESPAWNING:
				is_respawning.emit()
enum Status { ALIVE, DEAD, RESPAWNING }

func revive():
	state = Status.ALIVE

func die(_attacker: Attackable):
	state = Status.DEAD

func respawn():
	state = Status.RESPAWNING
