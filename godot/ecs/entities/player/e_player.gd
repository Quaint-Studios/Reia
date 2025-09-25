class_name Player
extends Entity

func on_ready() -> void:
	ECSUtils.sync_transform(self)
