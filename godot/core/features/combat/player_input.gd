extends Node

## Reference to the local player's ECS Entity
var local_player_entity: Entity

# Reusable buffer to avoid memory allocations
var writer := StreamPeerBuffer.new()

func _ready() -> void:
	# This is assigned when the SceneManager spawns the local character
	# local_player_entity = ...
	pass

func _physics_process(_delta: float) -> void:
	if not local_player_entity: return

	# Gather Movement Input
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Client-Side Prediction (Move locally immediately so it feels responsive)
	var move_comp := local_player_entity.get_component(C_MoveInput) as C_MoveInput
	if move_comp:
		move_comp.dir = input_dir

	# Send Input Tick to Server (Even if zero, to tell the server we stopped)
	writer.clear()
	writer.put_float(input_dir.x)
	writer.put_float(input_dir.y)

	# Target 0 implies "Send to Server"
	NetworkRouter.client.queue_packet(0, OpCode.ID.INPUT_TICK, writer.data_array)

func _unhandled_input(event: InputEvent) -> void:
	if not local_player_entity: return

	# Example: Casting a Fireball
	if event.is_action_pressed("cast_fireball"):
		var target_entity := _get_current_target()
		if not target_entity: return

		# Resolve Network ID for the payload
		var target_net_id := EntityMap.client.get_network_id(target_entity)
		var skill_id := 42 # e.g., Fireball ID in the skill registry

		# Pack the Payload
		writer.clear()
		writer.put_64(target_net_id)
		writer.put_u16(skill_id)

		# Send to Server Outbox
		NetworkRouter.client.queue_packet(0, OpCode.ID.CAST_SKILL, writer.data_array)

		# Optional: Play a client-side animation immediately for responsiveness
		# (But do NOT apply damage or subtract mana here!)

func _get_current_target() -> Entity:
	# Logic to fetch the currently selected target (e.g., from a raycast or UI target frame)
	return null
