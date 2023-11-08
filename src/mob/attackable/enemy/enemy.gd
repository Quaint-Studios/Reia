class_name Enemy extends Attackable

# Add things like pathfinding and AI
@export var loot: LootTable = LootTable.new() # TODO: Instead of Array[Item], use a Resource of type LootTable
#  LootTable should have the items: Array[Item] in it. This way it can be used
# in things like Bestiaries to get the loot the enemy drops specifically.

func _ready():
	status.is_dead.connect(_on_died)
	pass

func _on_died():
	if status.state != AttackableStatus.Status.DEAD:
		return

	# Spawn Item
	var loot_spawner := LootSpawner.instance

	if loot_spawner == null:
		print_debug("Error in Enemy %s, LootSpawner does not exist." % name)
		# Consider generating a new LootSpawner... maybe LootSpawner.create()?
		# Or Map.setup() so all maps always have the proper root setups?
		return

	if loot.size() > 0:
		loot_spawner.spawn(loot.items, position)

	despawn()

	# attach a new timer.
	# dissolve and delete this enemy.
	# create an enemy handler to reinstantiate this enemy.

func despawn():
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(queue_free)
	timer.autostart = true
	add_child(timer)
