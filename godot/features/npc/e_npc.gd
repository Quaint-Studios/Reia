class_name Npc
extends Entity

func define_components() -> Array:
	return [
		C_AimState.new(),
		C_Transform.new()
	]

func on_ready() -> void:
	ECSUtils.sync_transform(self)
