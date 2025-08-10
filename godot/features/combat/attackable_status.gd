class_name AttackableStatus extends Resource
## The status for an attackable. Generally just their current state.

###
### Signals
###
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
enum Status {ALIVE, DEAD, RESPAWNING}

func alive() -> void:
	state = Status.ALIVE

func die(_attacker: Attackable) -> void:
	state = Status.DEAD

func revive() -> void:
	state = Status.RESPAWNING
	# TODO: Do some animation or something
