class_name DungeonEntrance extends Area3D

# When the user enters the dungeon, we will create a new instance of the dungeon
# and set it as a child of this area. This way, the dungeon will be loaded and
# ready to go when the player walks further down the entrance.
func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("player"):
		#var dungeon = Dungeon.new()
		#add_child(dungeon)
		#area.queue_free()
		pass
