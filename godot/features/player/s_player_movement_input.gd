class_name PlayerMovementInputSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_LocalPlayer, C_MoveInput]).iterate([C_MoveInput])

func process(entities: Array[Entity], _components: Array[Array], _delta: float) -> void:
	var move_inputs := _components[0] as Array

	for i in range(entities.size()):
		var move: C_MoveInput = move_inputs[i]
		var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		var y := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
		move.dir = Vector2(x, y)

		move.sprint = Input.is_action_pressed("sprint") # e.g., Shift
		move.jump_pressed = Input.is_action_just_pressed("jump")
