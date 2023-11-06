class_name Enemy extends Attackable

# Add things like pathfinding and AI
var loot: Array[Item] = []

func _init():
	status.state_changed.connect(_on_died)

func _on_died():
	pass
	# Spawn Item
	# var dropped_items := DroppedItems.new(loot)

	# attach a new timer.
	# dissolve and delete this enemy.
	# create an enemy handler to reinstantiate this enemy.
