class_name CameraGlobal

var camera_state: CameraStateData = CameraStateData.new()

# Cached Components

func process(_delta: float) -> void:
	if not LocalCache.is_valid():
		load_player()

		if not LocalCache.is_valid():
			return

func load_player() -> void:
	if ECS.world == null:
		return

	var player_entity := ECS.world.query.with_all([C_LocalPlayer]).execute_one()
	if player_entity != null:
		LocalCache.set_player(player_entity)
