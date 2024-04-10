extends Timer

func _on_timeout() -> void:
	%MapViewport.render_target_update_mode = SubViewport.CLEAR_MODE_ONCE
	%MapViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
