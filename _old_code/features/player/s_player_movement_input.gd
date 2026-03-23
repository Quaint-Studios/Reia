class_name PlayerMovementInputSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_LocalPlayer, C_MoveInput]).iterate([C_MoveInput])

func process(_entities: Array[Entity], components: Array[Array], _delta: float) -> void:
	var move: C_MoveInput = components[0][0]

	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	move.dir = Vector2(x, y)

	if move.dir.length_squared() < 0.000001:
		move.state = C_MoveInput.MovementState.IDLE
	elif Input.is_action_pressed("run"):
		move.state = C_MoveInput.MovementState.RUN
	elif Input.is_action_pressed("walk"):
		move.state = C_MoveInput.MovementState.WALK
	elif Input.is_action_pressed("crouch"):
		move.state = C_MoveInput.MovementState.CROUCH
	else:
		move.state = C_MoveInput.MovementState.JOG

	move.jump_pressed = Input.is_action_just_pressed("jump")
