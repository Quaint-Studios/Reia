class_name Player
extends Entity

func define_components() -> Array:
	return [
		C_AimState.new(),
		C_CameraState.new(),

		C_Transform.new(),
		C_Velocity.new(),

		# C_LocalPlayer.new(),
		# C_Transform.new(),
		# C_Velocity.new(),
		# C_CharacterBodyRef.new(),
		# C_CameraTarget.new(),

		# C_DashIntent.new(),
		# C_JumpState.new(),
		# C_PlayerAbilityState.new(),

		# C_Health.new(100.0),
		# C_Ether.new(100.0),
		# C_Stamina.new(100.0)
	]
