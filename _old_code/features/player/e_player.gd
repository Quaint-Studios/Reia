class_name Player
extends Entity

func define_components() -> Array:
	return [
		C_AimState.new(),

		C_Transform.new(),
		C_Velocity.new(),

		C_MoveInput.new(),
		C_PlayerJumpState.new(),
		C_PlayerMovementConfig.new(),

		C_Player.new(),
		# C_LocalPlayer.new(), # Mark this entity as the local player

		# C_Health.new(100.0),
		# C_Ether.new(100.0),
		# C_Stamina.new(100.0)
	]
