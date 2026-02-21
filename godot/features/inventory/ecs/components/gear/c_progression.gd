class_name C_Progression
extends Component

@export var level: int = 1
@export var xp: int = 0

@export var breakthrough_level: int = 0 # increments when you "breakthrough"
@export var pending_breakthrough: bool = false # xp can accumulate even when blocked
