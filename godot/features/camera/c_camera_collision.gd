class_name C_CameraCollision
extends Component

# Spring arm config
@export var base_length: float = 6.0
@export var margin: float = 0.2
@export var collision_mask: int = 1

# Extension smoothing
@export var recover_rate: float = 6.0

# Effective runtime length (write-only by system)
var effective_length: float = base_length
